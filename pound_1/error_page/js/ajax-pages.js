$(function() {
	// Required for the close button to function if placed within the ajax'ed HTML pages.
	$("#close").click(function() {
		$("#overlay").overlay({api:true, close: '#close'}).close(); // Must include {api:true, close: '#close'} to prevent overlay from adding extra HTML for close button
	});
	
	// Removes Search text on focus, changes text to #9d9d9d and back to #666 out of focus
	var inputs = document.getElementsByTagName("input");
	for (var i = 0; i < inputs.length; i++) {
		if (inputs[i].name == "search") {
			inputs[i].style.color = "#9d9d9d";
			inputs[i].onfocus = function() {
				if (this.value == "search...") {
            		this.value = "";
        		}
        		this.style.color = "#666";
        	}
			inputs[i].onblur = function() {
        		if (this.value == "") {
            		this.value = "search...";
        		}
        		this.style.color = "#9d9d9d";
        	}            
     	}
  	}
});