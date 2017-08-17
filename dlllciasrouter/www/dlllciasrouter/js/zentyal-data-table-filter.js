if (typeof(_do_filtered) === 'undefined') {
    _do_filtered = false;
}

$(function () {
    var getQueryVariable = function (variable) {
        var query = window.location.search.substring(1);
        var vars = query.split("&");
        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split("=");
            if (pair[0] === variable) {
                return pair[1];
            }
        }
        //alert('Query Variable ' + variable + ' not found');
        return undefined;
    };
	
    var _filter = getQueryVariable("filter");
	
    if (_do_filtered === true) {
		location.href = "#filter_" + _filter;
		return;
	}
	
	if (_filter !== undefined) {
		$(".tableSearch").find("input:text").val(_filter);
		$(".tableSearch").find("input:submit").click();
		
		_do_filtered = true;
	}
});

// ------------------------------

/**
 * 讓點選說明的時候會跳到編輯的畫面
 * @author Pulipuli Chen 20170817
 */
var _setupDetailsEditorClickEvent = function () {
    var _desc_td = $("#VMServer_tbody > tr > td.tcenter > span.description");
    
    if (_desc_td.length === 0) {
        _desc_td = $("#VMServer_tbody > tr > td.tcenter:eq(7)");
    }
    
    _desc_td.click(function () {
        var _td = $(this);
        var _tr = _td.parents("tr:first");
        var _action_edit = _tr.children().filter("td:last").find("button.btn-edit");
        var _onclick = _action_edit.attr("onclick");
        // VMServer_description_row
        // Zentyal.TableHelper.showChangeRowForm('/dlllciasrouter/Controller/VMServer','VMServer','VMServer','changeEdit','vms1', 0, 0)
        eval(_onclick);
        setTimeout(function () {
            location.href = "#VMServer_description_row";
        }, 100);
    });
};

$(function () {
    _setupDetailsEditorClickEvent();
});