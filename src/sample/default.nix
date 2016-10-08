{ pkgs ? import <nixpkgs> {}
, enableDrafts ? false
, siteUrl ? null
, lastChange ? null
}@args:

let lib = import ./lib pkgs;
in with lib;

let

  # Load the configuration
  conf = overrideConf (import ./conf.nix) args;

  # Set the state
  state = { inherit lastChange; };

  # Function to load a template with a generic environment
  loadTemplate = loadTemplateWithEnv genericEnv;

  # Generic template environment
  genericEnv = { inherit conf state lib templates; };

  # List of pages to include in the navbar
  navbar = [ (head pages.archives) pages.about ];

  # List of templates
  templates = {
    # layout template loading
    # Example of setting a custom template environment
    layout  = loadTemplateWithEnv
                (genericEnv // { inherit navbar; feed = pages.feed; })
                "layout.nix";

    index   = loadTemplate "index.nix";

    generic = loadTemplate "generic.nix";

    archive = loadTemplate "archive.nix";

    feed    = loadTemplate "feed.nix";

    pagination  = loadTemplate "pagination.nix";

    breadcrumbs = loadTemplate "breadcrumbs.nix";

    navbar = {
      main = loadTemplate "navbar.main.nix";
      brand = loadTemplate "navbar.brand.nix";
    };

    post = {
      full     = loadTemplate "post.full.nix";
      list     = loadTemplate "post.list.nix";
      atomList = loadTemplate "post.atom-list.nix";
    };
  };

  # Pages attribute set
  pages = rec {

    # Index page
    # Example of extending a page attribute set
    index = {
      title = "Home";
      href = "index.html";
      template = templates.index;
      inherit feed;
      posts = take conf.postsOnIndexPage posts;
      archivePage = head archives;
    };

    # About page
    # importing content from a markdown file
    about = {
      href = "about.html";
      template = templates.generic;
      breadcrumbs = [ index ];
    } // (parsePage { dir = conf.pagesDir; file = "about.md"; });

    # Post archives pages generated by spliting the number of posts on multiple pages
    archives = splitPage {
      baseHref = "archives/posts";
      template = templates.archive;
      items = posts;
      itemsPerPage = conf.postsPerArchivePage;
      title = "Posts";
      breadcrumbs = [ index ];
    };

    # RSS feed page
    feed = { href = "feed.xml"; template = templates.feed; posts = take 10 posts; layout = id; };

    # List of posts
    # Fetch and sort the posts and drafts (only if enableDrafts is true) and set the
    # template
    posts = let
      substitutions = { inherit conf; };
      posts = getPosts { inherit substitutions; from = conf.postsDir; to = "posts"; };
      drafts = optionals enableDrafts (getDrafts { inherit substitutions; from = conf.draftsDir; to = "drafts"; });
      preparePosts = p: p // { template = templates.post.full; breadcrumbs = with pages; [ index (head archives) ]; };
    in sortPosts (map preparePosts (posts ++ drafts));

  };

  # Convert the `pages` attribute set to a list and set a default layout
  pageList =
    let list = (pagesToList pages);
    in map (setDefaultLayout templates.layout) list;

in generateSite { inherit conf; pages = pageList; }
