inherit "classes/Script";
#include <database.h>
#include <classes.h>

mapping execute(mapping vars)
{
    werror("(WE WON'T REST %O)\n", vars->request);
    mapping result = ([]);
    object o;

    result->me = describe_object(this_user());
    catch{ result->me->session = this_user()->get_session_id(); };
    catch{ result->me->vsession = this_user()->get_virtual_session_id(); };

    result->__version = _get_version();

    if (vars->__body)
    {
        vars->_json = vars->__body;
        vars->__data = Standards.JSON.decode(vars->__body);
        werror("(REST %O)\n(REST %O)\n", vars->__data, vars->__body);
    }

    if (this()->get_object()["handle_"+vars->request])
    {
        result += this()->get_object()["handle_"+vars->request](vars);
    }
    else if (vars->request[0] == '/')
        o = _Server->get_module("filepath:url")->path_to_object(vars->request);
    else
    {
        o = GROUP(vars->request);
        if (!o)
            o = USER(vars->request);
    }

    mixed type_result;
    if (o && vars->type)
       type_result = OBJ("/scripts/type-handler.pike")->run(vars->type, o, vars->data);

    if (type_result)
        result[vars->type] = type_result;
    else if (o && o->get_class() == "User")
        result += handle_user(o, vars);
    else if (o && o->get_class() == "Group")
        result += handle_group(o, vars);
    else if (o)
        result += handle_path(o, vars);
    else
    {
        result->error = "request not found";
        result->request = vars->request;
    }

    werror("(rest) %O\n", result);

    return ([ "data":Standards.JSON.encode(result), "type":"application/json" ]);
}

mapping handle_user(object user, mapping vars)
{
    mapping result = ([]);
    result->user=describe_object(user);
    result->request = vars->__data;
    return result;
}

mapping handle_group(object group, mapping vars)
{
    mixed err;
    mixed res;
    if (vars->__data && sizeof(vars->__data))
    {
        err = catch{ res = postgroup(group, vars->__data); };
    }

    mapping result = describe_object(group, 1);
    catch{ result->menu = describe_object(group->query_attribute("GROUP_WORKROOM")->get_inventory_by_class(CLASS_ROOM)[*]); };
    catch{ result->documents = describe_object(group->query_attribute("GROUP_WORKROOM")->get_inventory_by_class(CLASS_DOCHTML)[*], 1); };
    result->subgroups = describe_object(group->get_sub_groups()[*]);
    if (err)
       result->error = sprintf("%O", err[0]);
    if (objectp(res))
        result->res = describe_object(res);
    else if (res)
       result->res = sprintf("%O", res);
    return result;
}

mapping describe_object(object o, int|void show_details)
{
    function get_path = _Server->get_module("filepath:url")->object_to_filename;
    mapping desc = ([]);
    if (show_details)
        desc += prune_attributes(o);
    desc->oid = o->get_object_id();
    desc->path = get_path(o);
    desc->title = o->query_attribute("OBJ_DESC");
    desc->name = o->query_attribute("OBJ_NAME");
    desc->class = o->get_class();
    if (o->query_attribute("event"))
        desc->type = "event";

    if (o->get_class() == "User")
    {
        desc->id = o->get_identifier();
        desc->fullname = o->query_attribute("USER_FULLNAME");
        desc->path = get_path(o->query_attribute("USER_WORKROOM"));
        if (show_details && o == this_user())
            desc->trail = describe_object(Array.uniq(reverse(o->query_attribute("trail")))[*]);
    }

    if (o->get_class() == "Group")
    {
        object workroom = o->query_attribute("GROUP_WORKROOM");
        desc->id = o->get_identifier();
        desc->name = (o->get_identifier()/".")[-1];
        desc->path = get_path(workroom);
        if (show_details)
        {
            //object schedule = workroom->get_object_byname("schedule");
            //if (schedule)
            //    desc->schedule = schedule->get_content();
            if (o->is_member(this_user()))
                desc->members = describe_object(o->get_members(CLASS_USER)[*]);
            if (o->get_parent())
                desc->parent = describe_object(o->get_parent());
            if (o->query_attribute("event"))
                desc->event=o->query_attribute("event");
        }
    }

    if (o->get_object_class() & CLASS_DOCUMENT)
    {
        desc->mime_type = o->query_attribute("DOC_MIME_TYPE");
        catch { desc->size = sizeof(o->get_content()); };

        if (show_details && o->query_attribute("DOC_MIME_TYPE")[..3]=="text")
            catch { desc->content = o->get_content(); };
    }

    return desc;
}

mapping handle_path(object o, mapping vars)
{
    if (o->get_object_class() & CLASS_ROOM)
        this_user()->move(o);
    mapping result = ([]);

    if (vars->__data && vars->__data->update)
    {
        mapping update = vars->__data->update;
        if (update->name && update->name != o->get_identifier())
            o->set_identifier(update->name);
        if (update->title && update->title != o->query_attribute("OBJ_DESC"))
            o->set_attribute("OBJ_DESC", update->title);
        if (update->content && update->content != o->get_content())
            o->set_content(update->content);
        result->update = update;
    }

    result->object = describe_object(o, 1);
    if (o->get_environment())
        result->environment = describe_object(o->get_environment());

    if (o->get_object_class() & CLASS_CONTAINER)
        result->inventory = describe_object(o->get_inventory()[*]);

    return result;
}

mapping prune_attributes(object o)
{
    mapping pruned = ([]);
    mapping attributes;

    catch{ attributes = o->get_attributes(); };
    if (!attributes)
        return pruned;

    foreach (attributes; string attribute; mixed value)
    {
        if ( !(< "DOC_VERSIONS" >)[attribute] &&
             !(< "CONT", "OBJ", "ROOM", "DOC", "GROUP" >)[(attribute/"_")[0]] &&
             !(< "xsl", "web" >)[(attribute/":")[0]] )
        {
            pruned[attribute] = "ok";
            catch{ pruned[attribute] = o->query_attribute(attribute); };

            if (objectp(pruned[attribute]))
            {
                pruned[attribute] = ([ "oid":pruned[attribute]->get_object_id() ]);
                catch{ pruned[attribute] = describe_object(pruned[attribute]); };
            }
        } 
    }
    return pruned;
}

string|object postgroup(object group, mapping post)
{
    werror("(REST postgroup) %O\n", post);
    if (post->newgroup)
        return "old API for creating groups is no longer supported";

    if (post->type && this()->get_object()["handle_group_"+post->type])
        return this()->get_object()["handle_group_"+post->type](group, post);
    else
        return handle_group_post(group, post);
}

string|object handle_group_post(object group, mapping post)
{
    if (post->action == "new")
    {
        if (!post->name)
            return "name missing!";

        object factory = _Server->get_factory(CLASS_GROUP);
        object child_group = factory->execute( ([ "name":post->name, "parentgroup":group ]) );
        if (post->title)
            child_group->set_attribute("OBJ_DESC", post->title);
        return child_group;
    }
    else if (post->action == "update")
    {
        if (post->title)
            group->set_attribute("OBJ_DESC", post->title);
        if (post->name) // rename group
            return "renaming groups not yet supported";
        return group;
    }
    else
        return sprintf("action %s not supported", post->action);
}

string|object handle_group_event(object group, mapping post)
{
    group = handle_group_post(group, post);

    werror("(REST handling an event)\n");
    group->set_attribute("event", group->query_attribute("event")+post->event);
    return group;
}


void makeevent(object group, mapping data)
{
    werror("(REST making an event)\n");
    group->set_attribute("event", data);
}


mapping handle_login(mapping vars)
{
    mapping result =([]);
    if (vars->request == "login")
    {
        if (this_user() != USER("guest"))
            result->login = "login successful";
        else
            result->login = "user not logged in";
    }
    return result;
}

mapping handle_settings(mapping vars)
{
    mapping result =([]);
    if (vars->request == "settings")
    {
        if (vars->__data && sizeof(vars->__data))
            foreach (vars->__data; string key; string value)
            {
                if (this_user()->query_attribute(key) != value)
                    this_user()->set_attribute(key, value);
            }
        result->settings = this_user()->query_attributes() & (< "OBJ_DESC", "OBJ_NAME", "USER_ADRESS", "USER_EMAIL", "USER_FIRSTNAME", "USER_FULLNAME", "USER_LANGUAGE" >);
    }
    return result;
}

mapping handle_register(mapping vars)
{
    werror("REST: register\n");
    mapping result = ([]);
    result->request = vars->__data;

    object group = GROUP(vars->__data->group);
    if (!group)
    {
        result->error = sprintf("group not found: %O", vars->__data->group);
        return result;
    }

    string userid = vars->__data->userid||vars->__data->username;
    object olduser = USER(userid);
    object newuser;
    int activation;

    if (objectp(olduser))
        result->error = sprintf("user %s already exists", userid);
    else if (vars->__data->password != vars->__data->password2)
        result->error = "passwords do not match";
    else
    {
        mixed err = catch(seteuid(USER("root")));
        if(err)
        {
            result->error = sprintf("script permissions wrong!");
            result->debug = sprintf("%O", err);
        }
        else
        {
            err = catch {
                object factory  = _Server->get_factory(CLASS_USER);
                newuser = factory->execute( ([ "nickname":userid,
                                               "pw":vars->__data->password,
                                               "email":vars->__data->email,
                                               "fullname":vars->__data->fullname,
                                               "firstname":vars->__data->personalname,
                                             ]) );
                activation = factory->get_activation();
                if (testuser(newuser))
                    result->activation = activation;
            };
            if (err)
            {
                result->error = "failed to create user";
                result->debug = sprintf("%O", err);
            }
            else
            {
                object group = GROUP(vars->__data->group);
                if (!objectp(group))
                    result->error = "group missing";
                else
                {
                    err = catch(group->add_member(newuser));
                    if (err)
                        result->error = sprintf("failed to add new user to group: %O", group);
                    else
                        result->group = describe_object(group);

                    object pgroup = group;
                    object activationmsg;
                    while (!activationmsg && pgroup)
                    {
                        activationmsg = pgroup->query_attribute("GROUP_WORKROOM")->get_object_byname("account-activation");
                        if (!activationmsg)
                            pgroup = pgroup->get_parent_group();
                    }
                    if (!activationmsg)
                        result->error = "activation message not found";
                    else
                    {
                        string activationemail = activationmsg->get_content();
                        mapping templ_vars = 
                            ([ "(:userid:)":newuser->get_identifier(),
                               "(:activate:)":(string)activation,
                               "(:fullname:)":newuser->query_attribute("USER_FULLNAME")||"",
                               "(:email:)":newuser->query_attribute("USER_EMAIL"),
                               "(:group:)":group->query_attribute("OBJ_DESC") ]); 

                        if (!templ_vars["(:group:)"] || !sizeof(templ_vars["(:group:)"]))
                            templ_vars["(:group:)"] = group->get_identifier();

                        object from = group->get_admins()[0];
                        activationemail = replace(activationemail, templ_vars);
                        string mailfrom = sprintf("%s@%s", 
                                                from->get_identifier(),
                                                _Server->get_server_name());

                        array recipients = ({ newuser }) + group->get_admins();

                        recipients->mail(activationemail,
                                      activationmsg->query_attribute("OBJ_DESC"), 
                                      mailfrom, 
                                      activationmsg->query_attribute("DOC_MIME_TYPE"));

                    }
                    result->user = describe_object(newuser);
                }
            }
        }
    }
    return result;
}

mapping handle_activate(mapping vars)
{
    werror("REST: activate\n");
    mapping result = ([]);
    object user = USER(vars->__data->userid||vars->__data->username);
    if (!user)
        result->error = "no such user";
    else if (!user->get_activation())
        result->error = "user already activated";
    else if (!user->activate_user((int)vars->__data->activate))
        result->error = "invalid activation code";
    else
    {
        result->user = describe_object(user);
        result->result = "user is activated";
    }
    result->data = vars->__data;
    return result;
}

mapping handle_delete(mapping vars)
{
    mapping result = ([]);
    if (testuser(this_user())) //only test-users may be deleted without confirmation.
    {
        mixed err = catch(seteuid(USER("root")));
        if(err)
        {
            result->error = sprintf("script permissions wrong!");
            result->debug = sprintf("%O", err);
        }
        else
        {
            err = catch { result->delete = this_user()->delete(); };
        }
    }
    return result;
}

int testuser(object user)
{
    return (user->get_identifier()[..4] == "test.");
}

mixed _get_version()
{
    return ({ "2013-07-09-1", Calendar.Second(this()->get_object()->query_attribute("OBJ_SCRIPT")->query_attribute("DOCLPC_INSTANCETIME"))->format_time_short() });
}

