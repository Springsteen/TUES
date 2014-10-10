$(document).ready(function(){

    window.fbAsyncInit = function() {
        FB.init({
            appId      : '706460012762664',
            cookie     : true,
            xfbml      : true,  
            version    : 'v2.1'
        });
    };

    (function(d, s, id) {
        var js, fjs = d.getElementsByTagName(s)[0];
        if (d.getElementById(id)) return;
        js = d.createElement(s); js.id = id;
        js.src = "//connect.facebook.net/en_US/sdk.js";
        fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));
            

    $("#fb_btn").on("click", function(){
        FB.login(function(response){
            if (response['status'] != 'unknown'){    
                var userID = response['authResponse']['userID'];
                FB.api('/me', function(response) {
                    var userMail = response['email'];
                    // var userName = response['first_name'];
                    $.getJSON(
                        "/check_facebook_id", 
                        {userID : userID, userMail : userMail},
                        function(response){
                            if (response['status'] == "OK") {
                                window.location = document.URL + "types";
                            }
                        }
                    );
                });
            }
        }, {scope: 'public_profile,email'});
    });

    // setTimeout(
    //     function checkLoginState() {
    //         FB.getLoginStatus(function(response) {
    //             console.log("Im here");
    //             if (response['status'] != 'unknown'){
    //                 $( "#fb_btn" ).trigger( "click" );
    //             }
    //         });
    //     },
    //     5000
    // );


});