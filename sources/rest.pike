inherit "classes/Script";
#include <database.h>
#include <classes.h>

function get_path = _Server->get_module("filepath:url")->object_to_filename;

void rdebug(mapping result, mixed key, mixed data)
{
    if (GROUP("coder")->is_virtual_member(this_user()))
    {
        if (!result->debug)
            result->debug = ([]);
        result->debug[key] = data; 
    }
}


mapping execute(mapping vars)
{
    werror("(WE WON'T REST (%O %O))\n", vars->__internal->request_method, vars->request);
    mapping result = ([]);
    object o;
    array path_info;

    result->me = describe_object(this_user());
    catch{ result->me->session = this_user()->get_session_id(); };
    catch{ result->me->vsession = this_user()->get_virtual_session_id(); };
    rdebug(result, "trace", ({}));

    result->__version = _get_version();
    result->__date = Calendar.now()->format_time_short();
    

    if (vars->__body && vars->__internal->mime_type == "application/json")
    {
        vars->_json = vars->__body;
        vars->__data = Standards.JSON.decode(vars->__body);
        werror("(REST %O)\n(REST %O)\n", vars->__data, vars->__body);
    }
    else if (vars->__body)
    {
        rdebug(result, "notjson", vars-(< "fp" >));
        result->error = "this is not json";
    }

    if (this()->get_object()["handle_"+vars->request])
    {
        result += this()->get_object()["handle_"+vars->request](vars);
    }
    else if (stringp(vars->request) && vars->request[0] == '/')
    {
        o = _Server->get_module("filepath:tree")->path_to_object(vars->request);
        werror("(path_to_object %s %O)\n", vars->request, o);
        if (!o || (< PSTAT_FAIL_DELETED, PSTAT_DELETED >)[o->status()])
            [o, path_info] = get_path_info(vars->request);
        else if (vars->request[sizeof(vars->request)-11..]=="annotations")
            path_info = ({ "annotations" });
    }
    else if (stringp(vars->request))
    {
        array request_args = vars->request / "/";
        o = GROUP(request_args[0]);
        if (!o)
            o = USER(request_args[0]);
        path_info = request_args[1..];
    }

    mixed type_result;
    if (o && path_info && sizeof(path_info) && path_info[0]=="annotations")
    {
      type_result = handle_annotations(o, path_info[1..]);
    }
    else if (o && OBJ("/scripts/type-handler.pike"))
    {
        if (result->debug)
            result->debug->trace += ({ "calling type-handler" });
        type_result = OBJ("/scripts/type-handler.pike")->run(vars->__internal->request_method, o, path_info, vars->__data, vars);
        rdebug(result, "type_result", mappingp(type_result)?type_result->debug:type_result);
    }

    if (mappingp(type_result))
        result += type_result;
    else if (o && o->get_class() == "User")
        result += handle_user(o, vars);
    else if (o && o->get_class() == "Group")
        result += handle_group(o, vars, path_info);
    else if (o)
        result += handle_path(o, vars, path_info);
    else if (!vars->request)
        result->error = "request missing!";
    else
        result->error = "request not found";

    result->request = vars->request;
    result["request-method"] = vars->__internal->request_method;

    werror("(rest) %O\n", result);

    rdebug(result, "request", vars-(< "fp" >));

    string data = Standards.JSON.encode((["error":"unknown error"]));
    string type = "application/json";
    mixed err = catch
    {
      data = Standards.JSON.encode(result);
    };
    if (err)
    {
      data = sprintf("%O", ([ "error":err[0],
                              "trace": err,
                              "data": result ]));
      type = "text/plain";
    }

    return ([ "data":string_to_utf8(data), "type":type ]);
}

mapping handle_user(object user, mapping vars)
{
    mapping result = ([]);
    result->user=describe_object(user);
    result->request = vars->__data;
    return result;
}

mapping handle_group(object group, mapping vars, void|array path_info)
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
    if (search(path_info, "members") >= 0)
        result->members = describe_object(group->get_members(CLASS_USER)[*]);
    if (err)
       result->error = sprintf("handle_group %O", err[0]);
    if (objectp(res))
        result->res = describe_object(res);
    else if (res)
       result->res = sprintf("%O", res);
    return result;
}

mapping describe_object(object o, int|void show_details, int|void tree, int|void no_icon)
{
    mapping desc = ([]);
    if (show_details > 0)
        desc += prune_attributes(o);
    desc->oid = o->get_object_id();
    desc->path = get_path(o);
    desc->description = o->query_attribute("OBJ_DESC");
    desc->name = o->query_attribute("OBJ_NAME");
    desc->class = o->get_class();
    if (!no_icon)
        catch(desc->icon = describe_object(o->get_icon(), 0, 0, 1));
    if (o->query_attribute("event"))
        desc->type = "event";

    if (o->get_class() == "User")
    {
        desc->id = o->get_identifier();
        desc->fullname = o->query_attribute("USER_FULLNAME");
	desc->path = get_path(o->query_attribute("USER_WORKROOM"));
	if (show_details >= 2 && o == this_user())
            desc->trail = describe_object(Array.uniq(reverse(o->query_attribute("trail")))[*]);
    }

    if (o->get_class() == "Group")
    {
        object workroom = o->query_attribute("GROUP_WORKROOM");
        desc->id = o->get_identifier();
        desc->name = (o->get_identifier()/".")[-1];
        desc->path = get_path(workroom);
        if (show_details >= 2)
        {
            //object schedule = workroom->get_object_byname("schedule");
            //if (schedule)
            //    desc->schedule = schedule->get_content();
            if (o->is_member(this_user()))
                desc->members = describe_object(o->get_members(CLASS_USER)[*]);
            if (o->get_parent())
                desc->parent = describe_object(o->get_parent());
        }
        if (o->query_attribute("event"))
            desc->event=o->query_attribute("event");
    }

    if (o->get_object_class() & CLASS_DOCUMENT)
    {
        desc->title = o->query_attribute("OBJ_DESC");
        desc->mime_type = o->query_attribute("DOC_MIME_TYPE");
        catch { desc->size = sizeof(o->get_content()); };

        if (show_details >= 2 && (<"text","source">)[(o->query_attribute("DOC_MIME_TYPE")/"/")[0]])
            catch { desc->content = o->get_content(); };

//        if (show_details >= && o->query_attribute("DOC_MIME_TYPE")=="application/json")
//            catch { desc->data = o->get_content(); };
    }

    if (o->get_object_class() & CLASS_DOCEXTERN)
       desc->url = o->query_attribute("DOC_EXTERN_URL");

  catch {
    if (o->get_object_class() & CLASS_ROOM && tree)
    {
        desc->navigation = describe_object(o->get_inventory_by_class(CLASS_ROOM)[*], 0, tree);
    }
    else if (o->get_object_class() & CLASS_CONTAINER)
    {
        desc->container = describe_object(o->get_inventory_by_class(CLASS_CONTAINER)[*]);
    }
    if (o->get_object_class() & CLASS_CONTAINER)
    {
        desc->documents = sizeof(o->get_inventory_by_class(CLASS_CONTAINER|CLASS_DOCUMENT|CLASS_LINK));
        desc->links = sizeof(o->get_inventory_by_class(CLASS_DOCEXTERN));
    }
  };

    return desc;
}

mapping handle_path(object o, mapping vars, void|array path_info)
{
    string request_method = vars->__internal->request_method;
    mapping data = vars->__data;
    mapping attributes = ([]);

    if (!data)
        data = ([]); // simplify tests below

    if (mappingp(data))
        attributes = data->attributes || data - (<"title", "url", "content", "type", "class">);

    if (data->type && !data->class)
        data->class = data->type;

    werror("(REST handle_path %s %O)", request_method, o);
    mapping result = ([]);
    if (path_info && 
        (sizeof(path_info) && path_info[0] != "tree" && request_method != "PUT" || 
         sizeof(path_info) > 1))
    {
        result->error = ({ sprintf("can not find path %{/%s%} in %s", path_info, get_path(o)), path_info, describe_object(o, 0, 0, 1) });
        return result;
    }

    if (o->get_object_class() & CLASS_ROOM)
        this_user()->move(o);

    switch (request_method)
    {
      case "POST":
        if (vars["file[].filename"] && vars["file[]"])
        {
	    object factory = _Server->get_factory(CLASS_DOCUMENT);
            object newobject = factory->execute( ([ "name":vars["file[].filename"] ]) );
            newobject->set_content(vars["file[]"]||"");
            newobject->move(o);
            result->POST=sprintf("%O", newobject);
        }
        else 
        {
            if (data->name && data->name != o->get_identifier())
                o->set_identifier(data->name);
            if (data->title && data->title != o->query_attribute("OBJ_DESC"))
                o->set_attribute("OBJ_DESC", data->title);
            if (data->content && o->get_object_class() & CLASS_DOCUMENT && data->content != o->get_content())
                o->set_content(data->content);

            foreach (attributes; string attribute; mixed value)
            {
                if (value != o->query_attribute(attribute))
                    o->set_attribute(attribute, value);
            }
        }

        result->data = data;
      break;
      case "PUT":
        if (!path_info || !sizeof(path_info))
            result->error = "can not replace existing object with PUT";
        else if (sizeof(path_info)==1 && o->get_object_class() & CLASS_CONTAINER)
        {
          object factory;
          object newobject;
	  if ((data->url && !data->content && !data->class) || lower_case(data->class)=="link")
	  {
	    factory = _Server->get_factory(CLASS_DOCEXTERN);
	    newobject = factory->execute( ([ "name":path_info[0], "url":data->url||""]) );
	  }
	  if ((!data->url && data->content && !data->class) || lower_case(data->class)=="document")
	  {
	    factory = _Server->get_factory(CLASS_DOCUMENT);
            newobject = factory->execute( ([ "name":path_info[0] ]) );
            newobject->set_content(data->content||"");
	  }
	  if ((!data->url && !data->content) || (<"room", "container">)[lower_case(data->class)])
	  {
            // create room or container
            if (o->get_object_class() & CLASS_ROOM && !data->class || lower_case(data->class)=="room")
              factory = _Server->get_factory(CLASS_ROOM);
            else if (o->get_object_class() & CLASS_CONTAINER && !data->class || lower_case(data->class)=="container")
              factory = _Server->get_factory(CLASS_CONTAINER);
            newobject = factory->execute( ([ "name":path_info[0] ]) );
	  }

          if (!newobject)
            result->PUT="invalid arguments";
          else
          {
            newobject->set_attribute("OBJ_DESC", data->title);
            foreach (attributes; string attribute; mixed value)
            {
              newobject->set_attribute(attribute, value);
            }
            newobject->move(o);
            result->PUT=sprintf("%O", newobject);
          }
        }
      break;
      case "DELETE": // delete is done after describing the object, see below
      break;
      case "MOVE": // move object to destination
        object dest = _Server->get_module("filepath:tree")->path_to_object(vars->__internal->__headers->destination);
        if (dest)
          result->MOVE = !!o->move(dest);
      break;
    }

    result->object = describe_object(o, 2);
    if (o->get_environment())
        result->environment = describe_object(o->get_environment());

    mapping objclasses = ([ "room":CLASS_ROOM,
                            "container":CLASS_CONTAINER,
                            "document":CLASS_DOCUMENT,
                            "user":CLASS_USER,
                            "link":CLASS_DOCEXTERN
                            // FIXME: support more classes
                          ]);

    if (o->get_object_class() & (CLASS_CONTAINER))
    {
        if (vars->class)
            result->inventory = describe_object(o->get_inventory_by_class(objclasses[vars->class])[*], 0, 1);
        else if (vars->filter)
            result->inventory = describe_object(Array.filter(o->get_inventory(), lambda(object f){return f->query_attribute(vars->filter); })[*], 1);
        else
            result->inventory = describe_object(o->get_inventory()[*], 1);
    }

    if (o->get_object_class() & CLASS_ROOM && path_info && sizeof(path_info) && path_info[0]=="tree")
        result->navigation = describe_object(o->get_inventory_by_class(CLASS_ROOM)[*], 0, 1);

    if (request_method == "DELETE")
    {
      mixed err = catch(result->DELETE=!!o->delete());
      if (err)
        result->error = sprintf("%O", err); 
    }

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
        if ( !(< "DOC_VERSIONS", "trail" >)[attribute] &&
             !(< "CONT", "OBJ", "ROOM", "DOC", "GROUP", "USER" >)[(attribute/"_")[0]] &&
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
    else if ( stringp(post->action) )
        return sprintf("action %s not supported", post->action);
    else if ( !post->action )
        return sprintf("action missing");
    else
        return sprintf("action %O malformed", post->action);
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
        result->settings = this_user()->query_attributes() & (< "OBJ_DESC", "OBJ_NAME", "USER_ADRESS", "USER_EMAIL", "USER_FIRSTNAME", "USER_FULLNAME", "USER_LANGUAGE", "techgrind" >);
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
            rdebug(result, "setuid", sprintf("%O", err));
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
                rdebug(result, "create_user", sprintf("%O", err));
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
            rdebug(result, "delete", sprintf("%O", err));
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
    object instance = this()->get_object()->query_attribute("OBJ_SCRIPT");
    string instancetime;
    if (instance)
        instancetime = Calendar.Second(instance->query_attribute("DOCLPC_INSTANCETIME"))->format_time_short();
    return ({ "2013-07-09-1", instancetime });
}

array get_path_info(string path)
{

    object parent = OBJ("/");
    array path_info;
    array restpath = (path/"/")-({""});
    object o = parent->get_object_byname(restpath[0]);

    while (sizeof(restpath) && o && !(< PSTAT_FAIL_DELETED, PSTAT_DELETED >)[o->status()])
    {
        parent = o;
        restpath = restpath[1..];
        o = parent->get_object_byname(restpath[0]);
    }
    if (sizeof(restpath))
        path_info = restpath;

    werror("(get_path_info %O %O)\n", parent, path_info);
    // for some reason,  OBJ("/home")->get_object_byname("foo") does not return a proxy object.
    // ->this() fixes that, while on proxy objects it returns itself
    return ({ parent->this(), path_info });
}

mapping handle_annotations(object o, void|array path_info, void|int need_annotations)
{
    int all = path_info && sizeof(path_info) && path_info[0]=="all";
    mapping result = ([ "annotations":({}) ]);
    mapping obj = ([]);

    catch
    {
      if (o->get_annotating())
        obj = describe_annotation(o);
      else
        obj = describe_object(o, 1);
    };
    catch{ obj->annotations = describe_annotations(o, !all); };
    if (!need_annotations || (obj->annotations && sizeof(obj->annotations)))
        result->annotations += ({ obj });

    catch
    {
      if (all && o->get_object_class() & CLASS_CONTAINER)
      {
        foreach (o->get_inventory();; object oa)
        {
            mapping res = handle_annotations(oa, path_info, 1);
            if (res->annotations->annotations && sizeof(res->annotations->annotations))
                result->annotations += res->annotations;
        }
      }
    };
    return result;
}

array describe_annotations(object o, void|int all)
{
  array annotations = ({});

  foreach (o->get_annotations();; object a)
  {
    mapping annotation = describe_annotation(a);
    if (all)
      annotation->annotations = describe_annotations(a, all);
    annotations += ({ annotation });
  }
  return annotations;
}

mapping describe_annotation(object o)
{
  mapping annotation = ([]);
  //annotation->name = o->query_attribute("OBJ_NAME");
  annotation->parent = o->get_annotating()->query_attribute("OBJ_PATH");
  annotation->path = o->query_attribute("OBJ_PATH");
  annotation->subject = o->query_attribute("OBJ_DESC");
  annotation->content = o->get_content();
  annotation->oid = o->get_object_id();
  annotation->publication_date = o->query_attribute("OBJ_CREATION_TIME");
  annotation->modified = o->query_attribute("OBJ_LAST_CHANGED");
  annotation->author =   o->get_creator()->get_identifier();
  //annotation->doc_authors =   o->query_attribute("DOC_AUTHORS");
  annotation->version =   o->query_attribute("DOC_VERSION");
  annotation->cmodified = o->query_attribute("DOC_LAST_MODIFIED");


  return annotation;
}
