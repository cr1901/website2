alias ac := auto-commit

# Build website.
build:
  zola build --drafts

# Test website using a test server.
serve:
  zola serve --drafts

# Quickly save changes.
auto-commit AMEND="0" REASON="":
  -GIT_FLAGS="-am"; \
  AUTO_STR="Auto commit on `date \"+%Y-%m-%d at %H:%M:%S\"`."; \
  \
  if [ {{AMEND}} != "0" ]; then \
    GIT_FLAGS="--amend $GIT_FLAGS"; \
  fi; \
  \
  if ! [ -z "{{REASON}}" ]; then \
    AUTO_STR="$AUTO_STR Reason: {{REASON}}."; \
  fi; \
  git commit $GIT_FLAGS "$AUTO_STR"

# Build and deploy website.
deploy: build (auto-commit "0" "Deploying")
  rsync -zlHxihrptuv --rsh=/usr/bin/ssh public/ freebsd@wdj-consulting.com:/usr/local/www/site
  git push origin master
