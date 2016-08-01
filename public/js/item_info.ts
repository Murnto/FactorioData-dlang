/// <reference path="../../typings/jquery/jquery.d.ts" />

declare var modpack:string;

function _hoverFunc(e:any):void {
    "use strict";

    var el:JQuery = $(this);
    if (e.type === "mouseenter") {
        // still show the popover if the user left and returned hover
        el.data("cancelled", false);

        if (!el.data("loaded")) {
            el.data("loaded", true);

            $.get("/pack/" + modpack + "/api/popup/" + el.data("item-type") + "/" + el.data("item-name"), function (response:string):void {
                var po:any = (<any> el.unbind("hover")).popover({
                    content: response,
                    html: true,
                });
                po.popover(el.data("cancelled") ? "hide" : "show");
            });
        }
    } else if (e.type === "mouseleave") {
        // don"t show the popover when it loads
        el.data("cancelled", true);
    }
}
$(document).ready(function ():void {
    $("*[data-item-name]").hover(_hoverFunc);
});
