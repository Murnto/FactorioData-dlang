/// <reference path="../../typings/jquery/jquery.d.ts" />
(function () {
    var table = $("#table").find("tbody");
    var inputEl = $("#search");
    var inputTimer;
    function clearRows() {
        table.find("tr").remove();
    }
    function addRow(cols) {
        table.append("<tr><td>" + cols.join("</td><td>") + "</td></tr>");
    }
    function init() {
        clearRows();
    }
    function imgUrl(type, name) {
        return "<img src=\"icon/" + type + "/" + name + ".png\"/>";
    }
    function find(name) {
        $.get("api/find/" + name, function (data, status) {
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
    inputEl.bind("input", function (e) {
        window.clearTimeout(inputTimer);
        inputTimer = window.setTimeout(function () {
            var t = inputEl.val();
            console.log(t);
            find(t);
        }, 200);
    });
    find("iron");
}());
