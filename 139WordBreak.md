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
	- メモを使った方が早くなりそうと思いながらコードを書いていたが、
	メモがないとどのような入力の時に著しく遅くなるかを想定できていなかった
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

#### 2c
- Trieを使う方法
- 一旦動かなかったコードを置いておく
	- 後からよく考えたらtrieを実装しただけで問題の解には全くなっていないのでそりゃダメだ

```Go
type TrieNode struct {
	value    byte
	children []*TrieNode
}

func InitTrie(words []string) (root *TrieNode) {
	root = &TrieNode{byte(0), []*TrieNode{}}
	for _, w := range words {
		root.Insert(w)
	}
	return root
}

func (t *TrieNode) Insert(word string) {
	node := t
wordLoop:
	for i := 0; i < len(word); i++ {
		for _, child := range node.children {
			if child.value == word[i] {
				node = child
				goto wordLoop
			}
		}
		node.children = append(node.children, &TrieNode{word[i], []*TrieNode{}})
	}
}

func (t *TrieNode) Search(word string) bool {
	node := t
wordLoop:
	for i := 0; i < len(word); i++ {
		for _, child := range node.children {
			if child.value == word[i] {
				node = child
				goto wordLoop
			}
		}
		return false
	}
	return true
}

func wordBreak(s string, wordDict []string) bool {
	trieRoot := InitTrie(wordDict)
	return trieRoot.Search(s)
}
```

- 時間がかかりすぎてしまったので以下リンク先を真似て実装
	- https://github.com/hayashi-ay/leetcode/pull/61/files#diff-25f1226927fe56c505f4cbf2124534215d66f3c2ca0decf160a04dc095c93e83R31
- TLEになったけど入出力の合致するコードにはなったらしいので
一旦ここで退散
- trieはソフトウェアエンジニアの常識に含まれるかどうか微妙なところらしい
	- https://github.com/hayashi-ay/leetcode/pull/61/files#r1536822342 
	- https://discord.com/channels/1084280443945353267/1084283898617417748/1297919479074000908
- とりあえずtrieの概要は抑えたつもり

```Go
type TrieNode struct {
	character byte
	isWordEnd bool
	children  []*TrieNode
}

func InitTrie(words []string) (root *TrieNode) {
	root = &TrieNode{byte(0), false, []*TrieNode{}}
	for _, w := range words {
		root.Insert(w)
	}
	return root
}

func (t *TrieNode) Insert(word string) {
	node := t
	for i := 0; i < len(word); i++ {
		index := slices.IndexFunc(node.children, func(child *TrieNode) bool {
			return child.character == word[i]
		})
		if index > -1 {
			node = node.children[index]
			continue
		}
		child := &TrieNode{character: word[i]}
		node.children = append(node.children, child)
		node = child
	}
	node.isWordEnd = true
}

func (t *TrieNode) Search(word string) bool {
	node := t
	for i := 0; i < len(word); i++ {
		index := slices.IndexFunc(node.children, func(child *TrieNode) bool {
			return child.character == word[i]
		})
		if index == -1 {
			return false
		}
		node = node.children[index]
		continue
	}
	return true
}

func (t *TrieNode) GetAllMatchingPrefixes(word string) []string {
	prefix := ""
	prefixes := []string{}
	node := t
	for i := 0; i < len(word); i++ {
		index := slices.IndexFunc(node.children, func(child *TrieNode) bool {
			return child.character == word[i]
		})
		if index == -1 {
			break
		}
		prefix += string(word[i])
		if node.children[index].isWordEnd {
			prefixes = append(prefixes, prefix)
		}
		node = node.children[index]
	}
	return prefixes
}

func wordBreak(s string, wordDict []string) bool {
	trieRoot := InitTrie(wordDict)

	var backtrack func(s string) bool
	backtrack = func(s string) bool {
		if s == "" {
			return true
		}
		for _, word := range trieRoot.GetAllMatchingPrefixes(s) {
			if backtrack(s[len(word):]) {
				return true
			}
		}
		return false
	}

	return backtrack(s)
}
```

#### 2d
- 再帰
- memoに追加するタイミングが難しかった
- 時間計算量: O(len(s) * len(wordDict))
- 空間計算量: O(len(s))
- 参考: https://github.com/hayashi-ay/leetcode/pull/61/files#diff-25f1226927fe56c505f4cbf2124534215d66f3c2ca0decf160a04dc095c93e83R127

```Go
func wordBreak(s string, wordDict []string) bool {
	memo := make(map[int]bool) // falseのものだけmemoに追加

	var canSplitAtIndex func(index int) bool
	canSplitAtIndex = func(index int) bool {
		if index == len(s) {
			return true
		}
		if v, found := memo[index]; found {
			return v
		}
		for _, word := range wordDict {
			if !strings.HasPrefix(s[index:], word) {
				continue
			}
			if canSplitAtIndex(index + len(word)) {
				return true
			}
			memo[index+len(word)] = false
		}
		memo[index] = false
		return false
	}

	return canSplitAtIndex(0)
}
```

### Step 3
- 2bのコードが一番理解しやすかった

```Go
func wordBreak(s string, wordDict []string) bool {
	canBeSegmentedHead := make([]bool, len(s)+1)
	canBeSegmentedHead[0] = true
	for i := range s {
		if !canBeSegmentedHead[i] {
			continue
		}
		for _, word := range wordDict {
			if strings.HasPrefix(s[i:], word) {
				canBeSegmentedHead[i+len(word)] = true
			}
		}
	}
	return canBeSegmentedHead[len(s)]
}
```

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
- Trie
	- retrieval(失ったものを取り戻す)から命名された
	- 根が空ノードの連結リストで表現される
	- 注意: 空間計算量はtrieに格納され得る値のバリエーションによって決まる
		- ビットなら子ノードの数は高々2
		- 小文字アルファベットだけなら子ノードの数は26以下
		- unicodeの場合、子ノードの数は2Bになってしまうので
		入力サイズに気をつけないとメモリ使用量が膨大になってしまう
	- prefix searchでよく使われる
	- PATRICIA
	- 参考: https://medium.com/basecs/trying-to-understand-tries-3ec6bede0014
- Goのbyte型
	- uint8型のaliasである
	- なのでbyte型のnil値は0