// Switchery
var elems = Array.prototype.slice.call(document.querySelectorAll('.switch-btn'));
$('.switch-btn').each(function() {
	new Switchery($(this)[0], $(this).data());
});
