---
author:
  name: "Jack Collins"
title: "Specific Site OSINT"
subtitle: "jackcollins.me.uk | Platform Engineer & Linux Admin | UK"
date: 2023-01-19T17:50:57+01:00
draft: false
toc: false
images:
tags:
  - pentesting
  - osint
---

During pentesting, specifically during pre-engagement OSINT, we'll want to make use of various social media websites to gather information about our target.

This page is dedicated to listing specific details about some of the major social media sites, and how to go about gathering data from them.

Note: [Intelligence X Tools](https://intelx.io/tools) are good for a number of these sites.

---

- [LinkedIn](#linkedin)
- [Twitter](#twitter)
- [Facebook](#facebook)
- [Instagram](#instagram)
- [Snapchat](#snapchat)
- [Reddit](#reddit)
- [Tiktok](#tiktok)
- [Telegram](#telegram)

---

## LinkedIn {#linkedin}

Of note is the fact that you won’t be able to see as much information about someone if you are a third+ connection to them. You may need to attempt to find someone that knows them and connect to them on LinkedIn, in order to see more information about the target. This is where Sock Puppets come in.

After creating a fake account (Sock Puppet) on LinkedIn, don’t connect to too many people who don’t know you, as they may report you and you’ll get a ban.  
Instead, you could try and link to a few ‘LION’ users (use the search facility and search LION). This stands for ‘LinkedIn Open Network’ users, and they are more likely to accept random friend requests and not report you.

- Use LinkedIn's search box. Don’t forget about using [Operators](https://www.linkedin.com/help/linkedin/answer/a524335/using-boolean-search-on-linkedin?lang=en).
- Use Reverse image search against user profile and header pictures. See my [Useful Links]({{< ref "pentestinglinks.md" >}}) article including [Reverse Image Searching]({{< ref "pentestinglinks.md#reverseimage" >}})
- Search userIDs online to find other website profiles of possibly the same user. Don't forget Operators.
- Check the ‘contact information’ section on each profile
- Look through their Activity page, perhaps some articles give away further useful information such as company technologies, other profiles, etc.
- Check Previous employment locations, which could give you a rough idea of where they reside
- Experience and CVs may reveal the kind of software/hardware a target company uses
- Consider using their Interests to generate a wordlist, if you need to do any Brute Forcing.

---

## Twitter {#twitter}
- Use the search facility to it's fullest;
  - keyword, account or people/names.
  - operators similar to Google, such as quotations.
    - from: user1234
    - to: user5678
    - @user1234
    - from:user5678 since:2019-02-01 until:2019-03-01
    - from:joebloggs *searchterm*
    - geocode:long,lat,10km (get the long and lat from Google, 10km is the distance from the location) **Highly useful for pentesting against a specific company site. Find the long/lat of the company and search for all tweets that have the location tagged!**
    - Combine the above ideas!
- Be sure to look at which people a user is also tweeting directly to, maybe you can find people who are linked.
- Use the 'Advanced Search' feature on Twitter itself
- Use Reverse image search against user profile and header pictures. See my [Useful Links]({{< ref "pentestinglinks.md" >}}) article including [Reverse Image Searching]({{< ref "pentestinglinks.md#reverseimage" >}})
- [Search engine searches ]({{< ref "pentestinglinks.md#searchengines" >}}) - specify **site:twitter.com**

#### Links

- [TweetDeck](https://tweetdeck.twitter.com/)
- [Social Bearing](https://socialbearing.com/)
- [Mention Map](https://analytics.mentionmapp.com/)
- [Tweet Beaver](https://tweetbeaver.com/)
- [Spoonbill](https://spoonbill.io/)
- [Tinfoleak](https://tinfoleak.com/)
- [Intelligence X - Tools](https://intelx.io/tools?tab=twitter)

---

## Facebook {#facebook}

- Use the search box to it’s full extent
- Searching ‘photos of joe bloggs’ may show more photos than is available via their profile page!
- To find the 'UID' of a Favebook user, i.e.; their never changing User ID number (which can be useful for tools such as [Intelligence X](https://intelx.io/tools?tab-facebook)), then go to their profile page, go to source code and search for “userID”. It will show as ‘ “userID : “#” ‘
- Use Reverse image search against user profile and header pictures. See my [Useful Links]({{< ref "pentestinglinks.md" >}}) article including [Reverse Image Searching]({{< ref "pentestinglinks.md#reverseimage" >}})
- [Search engine searches ]({{< ref "pentestinglinks.md#searchengines" >}}) - specify **site:facebook.com**

#### Links
- [Sow Search](https://www.sowsearch.info/)
- [Intelligence X - Tools](https://intelx.io/tools?tab=facebook)

---

## Instagram {#instagram}

- You can view images full size (useful for downloading them for [Reverse Image Searching]({{< ref "pentestinglinks.md#reverseimage" >}})) by adding **/media?size=l** to the end of the image URL
- Search box;
full name, userIDs, hashtags
- Use CodeOfANinja to get the UID for the Instagram user, in case they ever change their username/handle. You can then still find them via their profile UID.
- [Search engine searches ]({{< ref "pentestinglinks.md#searchengines" >}}) - specify **site:instagram.com**

#### Links
- [Instaloader](https://github.com/instaloader/instaloader)
- [InstaDP](https://www.instadp.com/)
- [Find Instagram UserID - CodeNinja](https://www.codeofaninja.com/tools/find-instagram-user-id)
- [Imginn](https://imginn.com/)
- ~~wopita.com~~ (down at time of writing article)

---

## Snapchat {#snapchat}

There's not a huge amount for SnapChat, but then again you probably won't be using it much on a pentest. It's included here to cover all bases.

- Use Snapchat's own search facility
- [Snap Map](https://map.snapchat.com/) (maybe you can find a company's location on the Snap Map and see some posts that have been made from that location)

---

## Reddit {#reddit}

- Search box (don't forget to use Operators)
- Google; **intext: searchterm**
- Be sure to check both Posts and Comments for users, in Reddit itself. Comments might include additional information that leads to identifying information
- Use Reverse image search against user profile and header pictures. See my [Useful Links]({{< ref "pentestinglinks.md" >}}) article including [Reverse Image Searching]({{< ref "pentestinglinks.md#reverseimage" >}})
- [Search engine searches ]({{< ref "pentestinglinks.md#searchengines" >}}) - specify **site:reddit.com**

---

## Tiktok {#tiktok}

There's not a huge amount for Tiktok, but then again you probably won't be using it much on a pentest. It's included here to cover all bases.

- You can try looking for already known UserIDs on Tiktok using **https://tiktok.com/@userid**
- Use Reverse image search against user profile and header pictures. See my [Useful Links]({{< ref "pentestinglinks.md" >}}) article including [Reverse Image Searching]({{< ref "pentestinglinks.md#reverseimage" >}})
- You’ll have to manually search through a user's TikTok content yourself for possibly useful information

---

## Telegram {#telegram}

- [intelx.io](https://intelx.io/tools?tab=telegram)

---

[Top of page](#top)