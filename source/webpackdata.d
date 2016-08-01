import std.stdio;

import vibe.d;

import fact_pack;

class WebPackdata : Packdata
{
    URLRouter router;

    this(const string packpath)
    {
        super(packpath);
    }

    string resolve_img_url(const ItemAmount* iamt)
    {
        return "/pack/" ~this.meta.name ~ "/icon/" ~ iamt.info_type ~ "/" ~ iamt.name ~ ".png";
    }

    string resolve_img_url(T)(const T r)
    {
        return "/pack/" ~this.meta.name ~ "/icon/" ~ r.type ~ "/" ~ r.name ~ ".png";
    }

    string embed_image(T)(const T iamt, const string class_name = null)
    {
        return "<img " ~ (class_name ? "class=\"" ~ class_name ~ "\" "
                : "") ~ "src=\"" ~this.resolve_img_url(iamt) ~ "\" />";
    }

    string popover_anchor_start(const ref string type, const ref string name,
            string title = null, bool no_popover = false)
    {
        return "<a href=\"/pack/" ~this.meta.name ~ "/i/" ~ type ~ "/" ~ name ~ "\" title=\"" ~ title ~ (no_popover ? ""
                : "\" data-trigger=\"hover\" data-item-type=\"" ~ type
                ~ "\" data-item-name=\"" ~ name) ~ "\">";
    }

    string embed_item_popover(const ItemAmount* iamt)
    {
        Craftable* cft = resolve_craftable(iamt.info_type, iamt.name);
        const bool no_popover = cft is null || get_first_recipe_with_ingredients(cft) is null;
        return this.popover_anchor_start(iamt.info_type, iamt.name, cft.title,
                no_popover) ~this.embed_image(iamt) ~ "</a>";
    }
}
