var runMasonry = function(e) {
  $('#scrapbookImages').waitForImages(function () {
    doIt(this, false);
  });

  $('.masonry-grid').waitForImages(function () {
    doIt(this, true);
  });
};

var doIt = function (container, fitWidth) {
  var $container = $(container),
      $spinner   = $(".masonry-loading-spinner");
      gutter     = parseInt( $('.masonry').css('marginBottom') );

  $spinner.hide();
  $('.module').matchHeight();
  $container.parent().show();
  $container.masonry({
    gutter:       gutter,
    itemSelector: '.masonry',
    columnWidth:  '.masonry',
    isFitWidth:   fitWidth
  });
};

$(window).on('page:load', runMasonry);
$(window).on('load', runMasonry);


$(document).ready(function () {
  var setHeightBoxes = $("#profileHeader .wrapper").outerHeight();
  $('.stats a').height(setHeightBoxes -45)
});