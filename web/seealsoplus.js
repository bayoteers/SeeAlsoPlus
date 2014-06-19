/**
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (C) 2014 Jolla Ltd.
 * Contact: Pami Ketolainen <pami.ketolainen@jolla.com>
 */

function enhanceSeeAlso(result)
{
    result.infos.forEach(function(info) {
        var link = $(".bug_urls a[href='"+info.url+"']");
        if (link.size() == 0) return;
        if (link.size() > 1) {
            if(typeof(console) != 'undefined') {
                console.log("More than one see also link for url " + info.url, link);
            }
            return;
        }

        if (info.error) {
            link.attr('title', "Fetching remote data failed: " + info.error);
            return;
        }
        if (info.title) {
            link.text(info.title);
        } else {
            link.text(info.summary);
        }
        link.attr('title', info.status);

        // Type specific enhancements
        if (result.type == 'RemoteBugzilla') {
            link.addClass('bz_bug_link');
            link.addClass('bz_status_' + info.data.bug_status);
        }
        if (info.html) {
            var extraBtn = $("<button>")
                .attr('type', 'button')
                .text("More info")
                .addClass("sap-info-button")
                .button({
                    text: false,
                    icons: {primary: 'ui-icon-info'}
                })
                .click(function(){
                    if (info._infoBox) {
                        info._infoBox.dialog('open');
                    } else {
                        var infoBox = $(info.html);
                        info['_infoBox'] = infoBox;
                        infoBox.dialog({
                            position: 'right',
                            width: $("#bz_show_bug_column_2").width(),
                            minWidth: 700,
                            height: 500
                        })
                        .css('background-color', $('body').css('background-color'));
                    }
                });
            link.before(extraBtn);
        }
    })
}

$(function() {
    var urls = [];
    $(".bug_urls a").not(".bz_bug_link").each(function() {
        urls.push($(this).attr('href'));
    });
    if (urls.length > 0) {
        var rpc = new Rpc("SeeAlsoPlus", "get", {urls: urls,
                                                 html: 1});
        rpc.done(enhanceSeeAlso);
    }
});
