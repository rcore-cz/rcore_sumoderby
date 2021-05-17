var currentScore = 0;
var newScore = 0;

$("#killFeed").slideUp(0);

var maxNumberGive = 0;
var currentGive = 0;

function myFunction(){
	currentGive += Math.floor(Math.random() * 3); 
	if(currentGive > maxNumberGive){
		currentGive = maxNumberGive;
		setTimeout(recountNewScore, 1500)
	}
	else
	{
		setTimeout(myFunction, 15)
	}
	$(".toAddScore").text(currentGive);
}

function recountNewScore(){
	var random = Math.floor(Math.random() * 3); 
	currentScore  += random;
	maxNumberGive -= random;
	if(currentScore > newScore){
		currentScore = newScore;
		$(".toAddScore").text("");
		$(".toAddScore").css("font-size", "140px");
	}
	else
	{
		setTimeout(recountNewScore, 15)
	}
	$(".currentScore").text(currentScore);
	if(maxNumberGive < 0){
	    maxNumberGive = 0;
		$(".toAddScore").text("");
		$(".toAddScore").css("font-size", "140px");
	}
	else
	{
		$(".toAddScore").text(maxNumberGive);
	}
}

var Images = [
    "./destroyed.png",
    "./doublekill.png",
    "./multikill.png",
    "./fantastic.png",
];

$(function(){
    function display(bool) {
        if (bool) {
            $("#body").show();
        } else {
            $("#body").hide();
			currentScore = 0;
			newScore = 0;
			maxNumberGive = 0;
			currentGive = 0;
			$(".currentScore").text("0");
			$(".toAddScore").text("");
        }
    }
    display(false);

	window.addEventListener('message', function(event) {
		var item = event.data;
		if (item.type === "ui"){
			display(item.status);
		}

		if (item.type === "addScore"){
		    maxNumberGive += 100;
		    newScore += 100;
			setTimeout(myFunction, 15)
			$(".toAddScore").css("font-size", "140px");
            setTimeout(function(){
            	$(".toAddScore").css("font-size", "27px");
            }, 500)
		}

		if (item.type === "killFeed"){
		    if (Images[item.image] != null){
		        $("#killFeed").attr("src",Images[item.image]);
		    }else{
		        $("#killFeed").attr("src",Images[Images.length]);
		    }
            $("#killFeed").slideDown("slow", function(){
            	setTimeout(function(){
            		$("#killFeed").slideUp("slow");
            	}, 1000)
            });
		}
	})

});