問題: https://leetcode.com/problems/longest-substring-without-repeating-characters/description/

### Step 1
- O(n^2)時間で全探索する方法と、sliding windowを使う方法を思いついた
- sliding windowでやってみる
- 文字コードとか考慮しないといけなさそう
- テストケース
    - s="" -> 0
    - s="a" -> 1
    - s="ab" -> 2
    - s="abc" -> 3
    - s="aaa" -> 1
    - s="aba" -> 2
    - s="abcbdef" -> 4
    - s="abcbdefa" -> 5
- 時間計算量: O(n)
- 空間計算量: O(n)

```Go
func lengthOfLongestSubstring(s string) int {
	if len(s) == 0 {
		return 0
	}
	charToLastIndex := make(map[byte]int)
	charToLastIndex[s[0]] = 0
	result := 1
	left := 0
	right := 1
	for right < len(s) {
		rightChar := s[right]
		if i, found := charToLastIndex[rightChar]; found && left <= i {
			result = max(result, right-left)
			charToLastIndex[rightChar] = right
			left = i + 1
			right++
			continue
		}
		charToLastIndex[rightChar] = right
		right++
	}
	return max(result, right-left)
}
```

### Step 2
#### 2a
- step1の修正
- https://github.com/olsen-blue/Arai60/pull/49/files#diff-eaf04e4839867b1c256a01b37e3fd908cd889582123148e5910d72e4e4fcb421R53
    - 自分のやりたいことをより少ない行数で実装していた
- こちらの書き方の方が文字に対してrune型を使える
    - runeはint32のaliasでunicodeコードポイントを表現するので、byte型を使うより多くの文字を表現できる
    - 追記: 「マルチバイト文字」に対応できる
    - https://github.com/rihib/leetcode/pull/7/files#r1705447541

```Go
func lengthOfLongestSubstring(s string) int {
	charToLastIndex := make(map[rune]int)
	result := 0
	left := 0
	for right, c := range s {
		if i, found := charToLastIndex[c]; found && left <= i {
			left = i + 1
		}
		charToLastIndex[c] = right
		result = max(result, right-left+1)
	}
	return result
}
```

#### 2b
- leftを一気に飛ばさずにハッシュマップから除去しながら一つずつslideさせていく方法
- https://github.com/Yoshiki-Iwasa/Arai60/pull/42/files#diff-e7cfc7c77fde81f979e52c0e885012cb46b258eb1d473ac363c4384a73a8fa86R42
- 結構詰まった
- stringからピンポイントでrune型文字にアクセスする方法がわからなかった
    - `[]rune(s)`でsをrune型スライスにしてしまう
- `for _, found := charToLastIndex[rightChar]; found;`で毎回foundを計算し直してくれると思ったらしてくれなくて永遠に　left++　されてindex out of range
    - よく考えたらそれもそのはずで、for文の第１項は初期化条件なので、第３項かループ内でいじらないと更新されない

```Go
func lengthOfLongestSubstring(s string) int {
	sRune := []rune(s)
	chars := make(map[rune]struct{})
	result := 0
	left := 0
	for right := range sRune {
		rightChar := sRune[right]
		_, found := chars[rightChar]
		for ; found; _, found = chars[rightChar] {
			delete(chars, sRune[left])
			left++
		}
		chars[rightChar] = struct{}{}
		result = max(result, right-left+1)
	}
	return result
}
```

### Step 3
#### 3a
- leftを飛ばす

```Go
func lengthOfLongestSubstring(s string) int {
	charToLastIndex := make(map[rune]int)
	result := 0
	left := 0
	for right, c := range s {
		if i, found := charToLastIndex[c]; found && left <= i {
			left = i + 1
		}
		charToLastIndex[c] = right
		result = max(result, right-left+1)
	}
	return result
}
```

#### 3b
- leftを飛ばさない

```Go
func lengthOfLongestSubstring(s string) int {
	sRune := []rune(s)
	substringChars := make(map[rune]struct{})
	result := 0
	left := 0
	for right, c := range sRune {
		_, found := substringChars[c]
		for ; found; _, found = substringChars[c] {
			delete(substringChars, sRune[left])
			left++
		}
		substringChars[c] = struct{}{}
		result = max(result, right-left+1)
	}
	return result
}
```

### CS
- Goのbyteとrune
    - byte: uint8型のalias(バイトだから分かる)
    - rune: int32型のalias(いつも忘れる)
        - https://go.dev/ref/spec#Rune_literals 熟読する
        - unicodeコードポイントを表現する
        - シングルクオーテーションで囲まれる(知らなかった...)
        - \t: タブ
        - \x + 2桁16進数
        - \u + 4桁16進数
        - \U + 8桁16進数
        - \x + 3桁8進数 (ただし、0~255以外の数値はエラー)
    - runeの方が表現一つのデータ？で表現できる文字が多い
- escape sequence
    - \nで改行を表す、などのように\によって特別な記号を表現する方法。総称となる単語を知らなかった
- format specifiers
    - フォーマット指定子
    - こちらも総称を知らなかった
    - Goのrune型のフォーマット指定子
        - %v: コードポイントの元となる数値
        - %c: 文字
        - %q: '文字'
        - %U: 16進数で表現されるunicodeコードポイント(ex. U+1F600)
        - %#U: %Uと%qが両方出力される
- octal: 8
- UnicodeとUTF-8
    - いつもわからなくなる
    - Unicode: 世界中の文字を数値に対応させたものの集合体
    - UTF-8: Unicode文字を表現するための符号化方式
    - ex. 'あ'という文字はUnicodeで3042番のコードポイントが割り当てられており、
    これをUTF-8で表現すると E38182 になる