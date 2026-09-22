問題: https://leetcode.com/problems/is-subsequence/description/

### Step 1
#### 1a
- 手でやるなら s の文字を一文字ずつ t と照らし合わせていく（逆でも書けるだろうが、変）
- `lastMatchedCharIndexOfT` について、日本語で意味を考えて英語にしてみたらこうなってしまったが、
長すぎていまいち
- 考えるべきケースが多いのでテストケースをよく考えた
- テストケース
    - s="", t="" -> T
    - s="", t="a" -> T
    - s="a", t="" -> F
    - s="a", t="a" -> T
    - s="abc", t="abc" -> T
    - s="abc", t="xxaxxbxxcxx" -> T
    - s="abc", t="xxx" -> F
    - s="abc", t="xacx" -> F
    - s="abc", t="cba" -> F
- 時間計算量: O(s+t)
- 空間計算量: O(1)

```Go
func isSubsequence(s string, t string) bool {
	if s == "" {
		return true
	}
	lastMatchedCharIndexOfT := -1 // 最後にt上で見つかったsと一致する文字のインデックス
	for i := range s {
		charFound := false
		for j := lastMatchedCharIndexOfT + 1; j < len(t); j++ {
			if s[i] == t[j] {
				lastMatchedCharIndexOfT = j
				charFound = true
				break
			}
		}
		if !charFound {
			return false
		}
	}
	return 0 <= lastMatchedCharIndexOfT && lastMatchedCharIndexOfT < len(t)
}
```

- 他のやり方を考えてみる
    - 上記コードは ascii 文字にしか対応していないので、unicode に拡張してみる
    - ループの外側を t にしてみる
    - 正規表現を使ったら簡単にできそう（正規表現書けないから習得しないと、、）

#### 1b
- ループの外側を t にした方法
- 時間計算量: O(t)
- 空間計算量: O(1)

```Go
func isSubsequence(s string, t string) bool {
	if s == "" {
		return true
	}
	sIndex := 0
	for _, tc := range t {
		if tc == []rune(s)[sIndex] {
			sIndex++
			if sIndex == len(s) {
				return true
			}
		}
	}
	return false
}
```

### Step 2
#### 2a
- 1a の修正
- t のインデックスを 0 からにした
- rune 型（int32 型の alias）で回すことで unicode コードポイントに対応

```Go
func isSubsequence(s string, t string) bool {
	tIndex := 0
	for _, sr := range s {
		found := false
		for j, tr := range t[tIndex:] {
			if sr == tr {
				tIndex += j + 1
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}
```

#### 2b
- https://discord.com/channels/1084280443945353267/1225849404037009609/1243290893671465080
- 面白い見え方
- 再帰とループ両方実装してみる
- https://github.com/katsukii/leetcode/pull/10/files#diff-d427c32033f060b15b50c36529f4ce77d737efafa6389f4e00fea1930003a2e2R104
    - こういう書き方もできる

```Go
func isSubsequence(s string, t string) bool {
	var isSubsequenceHelper func([]rune, []rune) bool
	isSubsequenceHelper = func(sRunes, tRunes []rune) bool {
		if len(sRunes) == 0 {
			return true
		}
		if len(tRunes) == 0 {
			return false
		}
		if sRunes[0] == tRunes[0] {
			return isSubsequenceHelper(sRunes[1:], tRunes[1:])
		}
		return isSubsequenceHelper(sRunes, tRunes[1:])
	}

	sRunes, tRunes := []rune(s), []rune(t)
	return isSubsequenceHelper(sRunes, tRunes)
}
```

```Go
func isSubsequence(s string, t string) bool {
    sRunes, tRunes := []rune(s), []rune(t)
    si, ti := 0, 0
    for {
        if si == len(sRunes) {
            return true
        }
        if ti == len(tRunes) {
            return false
        }
        if sRunes[si] == tRunes[ti] {
            si++
        }
        ti++
    }
}
```

- ループのコード結構好き
- ti が毎ループインクリメントされていることがわかって、ti が len(tRunes) に到達したら終わるので
無限ループが必ず終了することがわりとすぐ読み取れる
- ただし、unicode に対応しようとすると、rune 型のスライスを作らないといけないので空間計算量が O(s+t) になってしまう

#### 2c
- https://github.com/fhiyo/leetcode/pull/55/files#diff-a6c7d5ff748fd033529b0b0a550ed2aa570e18edc3e2c61da5094aec0e23a91eR55

```Go
func isSubsequence(s string, t string) bool {
	tRuneToIndex := make(map[rune][]int)
	for i, tr := range t {
		tRuneToIndex[tr] = append(tRuneToIndex[tr], i)
	}
	tIndex := -1
	for _, sr := range s {
		i, _ := slices.BinarySearch(tRuneToIndex[sr], tIndex+1)
		if i == len(tRuneToIndex[sr]) {
			return false
		}
		tIndex = tRuneToIndex[sr][i]
	}
	return true
}
```

### Step 3
- 最終的に選んだのは、2b のループのコード
- rune 型のスライスを生成する必要を考慮するとパフォーマンス的にはどれも大差ない
- なら個人的に一番すっきり書けたと思ったものを選択

```Go
func isSubsequence(s string, t string) bool {
    sRunes, tRunes := []rune(s), []rune(t)
    si, ti := 0, 0
    for {
        if si == len(sRunes) {
            return true
        }
        if ti == len(tRunes) {
            return false
        }
        if sRunes[si] == tRunes[ti] {
            si++
        }
        ti++
    }
}
```

### CS