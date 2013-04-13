inherit "classes/Script";
#include <database.h>
#include <classes.h>

string execute(mapping vars)
{
    werror("WE WON'T REST");
    mapping data = ([]);
    object o;

    data->user = describe_object(this_user());

    if (vars->__body)
    {
        data->post = Standards.JSON.decode(vars->__body);
        werror("REST: %O\nREST: %O\n", vars->__body, data->post);
    }

    if (vars->request == "settings")
    {
        if (data->post && sizeof(data->post))
            foreach (data->post; string key; string value)
            {
                if (this_user()->query_attribute(key) != value)
                    this_user()->set_attribute(key, value);
            }
        data->settings = this_user()->query_attributes() & (< "OBJ_DESC", "OBJ_NAME", "USER_ADRESS", "USER_EMAIL", "USER_FIRSTNAME", "USER_FULLNAME", "USER_LANGUAGE" >);
    }
    else if (!vars->request || vars->request == "/")
    {
        data->classes = describe_object(Array.filter(this_user()->get_groups(), GROUP("ekita")->is_virtual_member)[*]);
        data->all_schools = describe_object(GROUP("ekita")->get_sub_groups()[*]);
    }
    else if (vars->request[0] == '/')
    {
        o = _Server->get_module("filepath:url")->path_to_object(vars->request);
        data = describe_object(o, 1);
        if (o->get_object_class() & CLASS_CONTAINER)
            data->documents = describe_object(o->get_inventory()[*]);
        if (o->get_object_class() & CLASS_ROOM)
            this_user()->move(o);
    }
    else
    {
        o = GROUP(vars->request)||USER(vars->request);
        if (o)
        {
            object err;
            if (data->post && sizeof(data->post))
            {
                err = catch{ create_subgroup(data->post->create_subgroup, o); };
            }

            data += describe_object(o, 1);
            data->menu = describe_object(o->query_attribute("GROUP_WORKROOM")->get_inventory_by_class(CLASS_ROOM)[*]);
            data->documents = describe_object(o->query_attribute("GROUP_WORKROOM")->get_inventory_by_class(CLASS_DOCHTML)[*], 1);
            data->subgroups = describe_object(o->get_sub_groups()[*]);
            if (err)
               data->error = sprintf("%O", err);
        }
        else
        {
            data->error = "request not found";
            data->request = vars->request;
        }
    }

    return Standards.JSON.encode(data);
}

mapping describe_object(object o, int|void show_details)
{
    function get_path = _Server->get_module("filepath:url")->object_to_filename;
    mapping desc = ([]);
    desc->oid = o->get_object_id();
    desc->path = get_path(o);
    desc->description = o->query_attribute("OBJ_DESC");
    desc->name = o->query_attribute("OBJ_NAME");

    if (o->get_class() == "User")
    {
        desc->id = o->get_identifier();
        desc->fullname = o->query_attribute("USER_FULLNAME");
        desc->path = get_path(o->query_attribute("USER_WORKROOM"));
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
            object schedule = workroom->get_object_byname("schedule");
            if (schedule)
                desc->schedule = schedule->get_content();
            desc->members = describe_object(o->get_members(CLASS_USER)[*]);
        }
    }

    if (o->get_object_class() & CLASS_DOCUMENT)
    {
        desc->mime_type = o->query_attribute("DOC_MIME_TYPE");
        if (show_details)
            catch { desc->content = o->get_content(); };
    }

    return desc;
}

object create_subgroup(string name, object parent)
{
    object factory = _Server->get_factory(CLASS_GROUP);
    return factory->execute( ([ "name":name, "parentgroup":parent ]) );
}
