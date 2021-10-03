# Build website.
build:
  zola build --drafts

# Test website using a test server.
serve:
  zola serve --drafts

# Build and deploy website.
deploy: build
  rsync -zlHxihrptuv --rsh=/usr/bin/ssh public/ freebsd@wdj-consulting.com:/usr/local/www/site
