class @FlashManager
  @closeFlashes = -> $('.flashes').fadeOut(2000)

$(document).ready ->
  setTimeout FlashManager.closeFlashes, 2000
