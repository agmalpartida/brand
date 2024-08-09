---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
lastmod: {{ .Date }}
description: "This description goes below the title"
type: "post"
tags: [testing]
projects: [albertogalvez]
gitIssue: 30
featuredImage: "https://cdn.cjri.uk/albertogalvez/static/images/test.jpg"
featuredImageAlt: "example text"
featuredImageCaption: "if you see this you're on a test post"
featuredImageExt: false
noFeaturedImage: false
---

## Things to consider

- Write below the `---` for text to appear on the post

- This is the default post created using the code `hugo new content/posts/(title of post here).md`

## Changing the Frontmatter

1. Change the description to something catchy. This will show below the title on the post itself and the post hero card

2. Most likely the type of page is a `post` but this can either be changed to `page` or `project`

3. Put the `tags` in following the convention `[tag1, tag2]` not forgetting the `, (comma)` between the tags

4. Featured images:

    4a. They are automatically placed in below  the tags. This field automatically loads an image from the CDN under the extension `.jpg` unless `noFeaturedImage` parameter is set to true

    4b. Please do not forget the `featuredImageAlt` parameter either! It is essential for accessability and SEO

5. Posts will not show up on the website until the `draft` parameter is either set to `false` or deleted from the template above and the post is out of the drafts folder `content/drafts`

6. If this post is part of a project or two please indicate that in the `projects` frontmatter like `projects: [albertogalvez,moviemadness]`

7. The site is version tracked using git as such all posts and projects have a corresponding issue. Please indicate the git issue using the convention `gitIssue: 14` in the frontmatter above

8. If the post has been modified please include the `lastmod` parameter to the current date. This will not change the posted date but will appear at the end of the post in small text "This page was last updated x"

## General "Rules of Thumb" for posts

1. Add an image every 2-3 paragraphs (see below)

2. At least 1 external text / image link per post

    Add external links by `[text to press for link](link to site)`

    `[Visit my Gitlab!](https://gitlab.com/albertogalvez/movie-madness)`

    Hello there! If you have time please [Visit my Gitlab!](https://gitlab.com/albertogalvez/movie-madness) I would very much appreciate it!

3. No HTML only Markdown

See [here](https://www.markdownguide.org/basic-syntax) for more info on Markdown.

## Adding Images in Posts

THe first step is to add the images to the CDN with the format `((post-name))-image1.jpg` an example being `lessons-in-hugo-wordpress-complacency-wordpress` where `lessons-in-hugo-wordpress-complacency` is the post name and `wordpress` is the name of the image.

Images are added to posts using the `{{</* img */>}}` shortcode.

`{{</* img 0 1 2 3 4  */>}}`

### 0. What type of image is it?

"int" = internal image (if the image is just for this post)

"cdn" = another image in the cdn

"ext" = an external image

### 1. The Name or URL of the image

If it's an internal image put the single image name like: `wordpress.jpg` (without the post title)

If it's a cdn image put the whole title of the image like: 'lessons-in-hugo-wordpress-complacency-wordpress.jpg'

If it is an external image just place the url of the image like: `"https://www.google.co.uk/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png"`

### 2. The ALT Text

The ALT text of an image is important not only for SEO but for Accessability.

[See this link here for the reason why](https://accessibility.huit.harvard.edu/describe-content-images)

`"A screenshot of my letterboxd profile showing I've watched 280 movies in the year 2022"`

Be as descriptive as possible in the context of the post

### 3. (OPTIONAL BUT RECOMMENDED)

A caption for the image. It could be the same as the alt text but could be a different.

If the alt text is:

`"A screenshot of my letterboxd profile showing I've watched 280 movies in the year 2022"`

Then the caption could be as simple as:

`"WOW! I've watched so many movies..."`

### 4. (OPTIONAL) Make the image link to another site

Sometimes you want to link to somewhere external like a website: (do not forget https://)

"https://google.com"

*Please note*: that you will not be allowed to link through images without first having a caption

### Examples of images using the above shortcode convention

Below here is the internal page image with the caption "what a nice room" and alt text "a royalty free picture of an open plan living room / kitchen"

```go-html
{{</* img cdn test-testing-image.jpg "a royalty free picture of an open plan living room / kitchen" "what a nice room" */>}}
```

{{< img cdn test-testing-image.jpg "a royalty free picture of an open plan living room / kitchen" "what a nice room" >}}

----

Below is an image that is another page/post on the site. (Note the `cdn` option). This image is the featured image from the about page

```go-html
{{</* img cdn about.jpg "a picture of me Conor Ryan overlooking the canal in Amsterdam" "what a lovely holiday!" */>}}
```

{{< img cdn about.jpg "a picture of me Conor Ryan overlooking the canal in Amsterdam" "what a lovely holiday!" >}}

----

Below is an external image from another website. This links to the google logo

```go-html
{{</* img ext "https://www.google.co.uk/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png" "the google logo" "this is a caption of an external image" */>}}
```

{{< img ext "https://www.google.co.uk/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png" "the google logo" "this is a caption of an external image">}}

----

Below is an example of a clickable image with a link to an external site

```go-html
{{</* img cdn the-personal-letterboxd-project-movie-stats.jpg "click to view my letterboxd stats page 280 films this year means 494 hours well spent" "click to view my letterboxd stats page" "https://letterboxd.com/albertogalvez/year/2022/" */>}}
```

{{< img cdn the-personal-letterboxd-project-movie-stats.jpg "click to view my letterboxd stats page 280 films this year means 494 hours well spent" "click to view my letterboxd stats page" "https://letterboxd.com/albertogalvez/year/2022/" >}}

