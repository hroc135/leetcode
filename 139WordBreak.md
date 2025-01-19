問題: https://leetcode.com/problems/word-break/description/

### Step 1
- まず思いついたのは、
sの接頭辞と合致する単語をwordDictから探す -> sの接頭辞を削り、スタックに入れる ->
合致する接頭辞を探す -> 接頭辞を削る -> 
を繰り返す方法
    - DFSぽい
- メモが使えそうかなと思ったが一旦使わずに入出力の合致するコードを書くことを優先
- テストケース
    - s="a", wordDict=["a"] -> true
    - s="aaa", wordDict=["a"] -> true
    - s="aaa", wordDict=["aa"] -> false
    - s="ab", wordDict=["a","b"] -> true
    - s="ab", wordDict=["a","b","c"] -> true
    - s="abc", wordDict=["a","b"] -> false
    - s="catsandog", wordDict=["cats","dog","sand","and","cat"] -> false
    - s="", wordDict=["a"] -> false
- 以下、TLEしたコード

```Go
func wordBreak(s string, wordDict []string) bool {
	initialToWord := make(map[byte][]string)
	for _, w := range wordDict {
		initial := w[0]
		initialToWord[initial] = append(initialToWord[initial], w)
	}

	suffixes := []string{s} // used as a stack
	for len(suffixes) > 0 {
		top := suffixes[len(suffixes)-1]
		suffixes = suffixes[:len(suffixes)-1]
		for _, w := range initialToWord[top[0]] {
			if !strings.HasPrefix(top, w) {
				continue
			}
			topSuffix := top[len(w):]
			if len(topSuffix) == 0 {
				return true
			}
			suffixes = append(suffixes, topSuffix)
		}
	}
	return false
}
```

- 上記コードでTLEになったのは以下のテストケース
    - s="aaa...b", wordDict=["a","aa","aaa","aaaa",...]
    - "a"で2回削られたsと"aa"で1回削られたsが同じ
    - 同じ接尾辞を繰り返し確認することになってしまう
    のでメモを使えばこの問題を解消できる
- メモを付けたら通った
- 時間計算量: O(len(s) * len(wordDict))
    - sの接尾辞はlen(s)パターンしかないから
    - メモがないと同じ接尾辞を何度も確認することになるのでO(len(s) * len((wordDict)^2))になる??
        - あまり自信はない
- 空間計算量: O(len(s)^2)
    - s="aaaaa"の時にsuffixesスタックに"aaaa", "aaa", "aa", "a"が同時に詰まれる場合があるのでO(len(s)^2 / 2)

```Go
func wordBreak(s string, wordDict []string) bool {
	initialToWord := make(map[byte][]string)
	for _, w := range wordDict {
		initial := w[0]
		initialToWord[initial] = append(initialToWord[initial], w)
	}

	suffixes := []string{s} // used as a stack
	checkedSuffixesMemo := make(map[string]struct{})
	for len(suffixes) > 0 {
		top := suffixes[len(suffixes)-1]
		suffixes = suffixes[:len(suffixes)-1]
		if _, found := checkedSuffixesMemo[top]; found {
			continue
		}
		for _, w := range initialToWord[top[0]] {
			if !strings.HasPrefix(top, w) {
				continue
			}
			topSuffix := top[len(w):]
			if len(topSuffix) == 0 {
				return true
			}
			suffixes = append(suffixes, topSuffix)
			checkedSuffixesMemo[top] = struct{}{}
		}
	}
	return false
}
```

### Step 2
#### 2a
- step1の改善
- memoに追加する/memoを参照するタイミングを修正
    - suffixesスタックにチェック済みの接尾辞を入れたくないので、
    入れる前にmemoを参照

```Go
func wordBreak(s string, wordDict []string) bool {
	initialToWord := make(map[byte][]string)
	for _, w := range wordDict {
		initial := w[0]
		initialToWord[initial] = append(initialToWord[initial], w)
	}

	suffixes := []string{s} // used as a stack
	checkedSuffixesMemo := make(map[string]struct{})
	for len(suffixes) > 0 {
		top := suffixes[len(suffixes)-1]
		suffixes = suffixes[:len(suffixes)-1]
		for _, w := range initialToWord[top[0]] {
			if !strings.HasPrefix(top, w) {
				continue
			}
			topSuffix := top[len(w):]
			if len(topSuffix) == 0 {
				return true
			}
			if _, found := checkedSuffixesMemo[topSuffix]; found {
				continue
			}
			suffixes = append(suffixes, topSuffix)
		}
		checkedSuffixesMemo[top] = struct{}{}
	}
	return false
}
```

#### 2b
- DPによって入力sが分割された時に単語の先頭文字となるインデックスを記録する方法
- 例: s = "catsandog", wordDict = ["cats","dog","sand","and","cat"]
	- canBeSegmented = [1, 0, 0, 1, 1, 0, 0, 1, 0] (0,1はブール値)
- 時間計算量: O(len(s) * len(wordDict))
- 空間計算量: O(len(s) + len(wordDict))
- step1では未チェックの接尾辞をスタックに入れていたが、
2bはDPでインデックスを管理するので空間計算量を抑えられる
- `wordDictInitialsToWords`はなくてもいいが２重ループの内側の無駄を削減できる
- 参考: https://github.com/goto-untrapped/Arai60/pull/20/files#diff-91f169b7b71eab1c0bb41005f23458ed043899b6323955fda29e392baa215b17R1

```Go
func wordBreak(s string, wordDict []string) bool {
	wordDictInitialsToWords := make(map[byte][]string)
	for _, w := range wordDict {
		wordDictInitialsToWords[w[0]] = append(wordDictInitialsToWords[w[0]], w)
	}

	canBeSegmented := make([]bool, len(s)+1)
	for i := 0; i < len(s); i++ {
		if i != 0 && canBeSegmented[i] == false {
			continue
		}
		for _, w := range wordDictInitialsToWords[s[i]] {
			if strings.HasPrefix(s[i:], w) {
				canBeSegmented[i+len(w)] = true
			}
		}
	}

	return canBeSegmented[len(canBeSegmented)-1]
}
```

### Step 3

### CS
- Goのmap
    - `var initialToWord map[byte][]string`
    でmapを初期化して値を書き込もうとしたらパニックした
    - Goのmapは参照型なので上記のように宣言したmapの値はnil
    - ビルトインのmake関数を使って初めてマップの割り当てが完了する
    - mapの初期化にvarを使うのはmapをグローバルに使いたい時くらい
    - 「面接での評価は相乗平均」という話を思い出した。
    「普段Goを使っています」と言いながらこのミスをしたら一発アウトなレベルだろう、、
    - https://go.dev/blog/maps