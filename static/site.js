
          
          
$('document').ready(function() {
  Mousetrap.bind('left', function() { if ($('.prev-post').length) window.location = $('.prev-post').attr('href'); });
  Mousetrap.bind('right', function() { if ($('.next-post').length) window.location = $('.next-post').attr('href'); });
});

