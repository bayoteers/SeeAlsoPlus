function enhanceSeeAlso(result)
{
    $(".bug_urls a").each(function() {
        var link = $(this);
        if (link.attr('href') != result.url) return;
        if (result.error) {
            link.attr('title', "Fetching remote data failed: " + result.error);
            return;
        }
        if (result.summary) {
            link.text(result.summary);
        }
        link.attr('title', result.status);
        // Type specific enhancements
        if (result.type == 'RemoteBugzilla') {
            link.addClass('bz_bug_link');
            link.addClass('bz_status_' + result.data.bug_status);
        }
    });
}

$(function() {
    $(".bug_urls a").not(".bz_bug_link").each(function() {
        var rpc = new Rpc("SeeAlsoPlus", "get", {url: $(this).attr('href'),
                                                 raw: 1});
        rpc.done(enhanceSeeAlso);
    });
});
