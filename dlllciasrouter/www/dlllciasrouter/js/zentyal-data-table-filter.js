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