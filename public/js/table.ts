/// <reference path="../../typings/jquery/jquery.d.ts" />
declare var _hoverFunc:(e:any) => void;

(function ():void {
    var table:JQuery = $("#table").find("tbody");
    var inputEl:JQuery = $("#search");
    var inputTimer:number;

    function clearRows():void {
        table.find("tr").remove();
    }

    function addRow(cols:string[]):void {
        table.append("<tr><td>" + cols.join("</td><td>") + "</td></tr>");
    }

    function init():void {
        clearRows();
    }

    function imgUrl(type:string, name:string):string {
        return "<img src=\"icon/" + type + "/" + name + ".png\"/>";
    }

    function find(name:string):void {
        $.get("api/find/" + name, function (data:any, status:any):void {
            clearRows();

            for (var ret in data) {
                if (!data.hasOwnProperty(ret)) {
                    continue;
                }

                ret = data[ret];
                console.log(ret);
                addRow([imgUrl(ret.type, ret.name), ret.type, "<a href=\"i/" + ret.type + "/" + ret.name + "\" title=\"" + ret.title + "\" data-trigger=\"hover\" data-item-type=\"" + ret.type + "\" data-item-name=\"" + ret.name + "\">" + (ret.title || ret.name) + "</a>"]);
            }

            $("*[data-item-name]").hover(_hoverFunc);
        });
    }

    init();

    inputEl.bind("input", function (e:any):void {
        window.clearTimeout(inputTimer);
        inputTimer = window.setTimeout(function ():void {
            var t:string = inputEl.val();
            console.log(t);
            find(t);
        }, 200);
    });

    find("iron");
}());
