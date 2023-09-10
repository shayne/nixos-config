{
  ga = "git add";
  gam = "git amend";
  gan = "git add -N";
  gap = "git add -p";
  gbc = "git branch -vv | grep ': gone]' | grep -v '\*' | awk '{ print $1; }' | xargs -pr git branch -D";
  gc = "git commit -v";
  gcd = "cd (git root)";
  gco = "git checkout";
  gcp = "git cherry-pick";
  gdiff = "git diff";
  gl = "git prettylog";
  gp = "git push";
  gpf = "git push --force-with-lease";
  gpu = "git push -u origin HEAD";
  gpuf = "git push -u origin HEAD --force-with-lease";
  gpl = "git pull --rebase";
  gs = "git status";
  gst = "git stash";
  gt = "git tag";

  godlv = "dlv exec --api-version 2 --listen=127.0.0.1:2345 --headless";
}
