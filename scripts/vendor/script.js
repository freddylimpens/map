$(document).ready(function(){
	
	wH = $(window).height();
	wW = $(window).width();
	$('.card.active .inner').height(wH - 308);

	$(document).on('click','.photo-widget #picture-file', function(){
			   $(this).siblings('input[type="file"]').click();
		       });

	$(document).on('click','#toolbar .connected a',function(){
		$('#connected-user-block').toggleClass('show');
	});
});
