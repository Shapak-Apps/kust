git add .
git commit -m "YAY! New commit, new changes!"
git branch -M main
git -c http.proxy=socks5h://127.0.0.1:10808 push origin main