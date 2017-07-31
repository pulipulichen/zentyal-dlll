$(function () {
    setTimeout(function () {
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

        var _backview = getQueryVariable("backview");
        //console.log(_backview);
        //alert(_backview);

        if (_backview !== undefined) {
            var _h1 = $("h1:first");
            //alert(_h1.length);
            var _domainName = _h1.text().trim().split(" ")[0];
            //alert(_domainName.split(".").length);
            if (_domainName.split(".").length > 1) {
                var _uri = _backview + "?filter=" + _domainName;
                var _a = $('<a href="' + _uri + '">' + _h1.html() + '</a>');
                _h1.html(_a);
            }
        }
    }, 0);
});