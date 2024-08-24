### Step 1
- 最初に思いついたのは、頭から一文字ずつ発生回数を数え、最初に見つかった発生回数1の文字のインデックスを返す方法
  - ただ、このやり方は時間計算量O(n^2)で、見積もり実行時間は、10^5^2 = 10^10 -> 10^8で割って100秒 になってしまうので他の方法を考えることに
- 採用したアルゴリズムは、(1)一文字ずつ、出現するインデックスをスライスに溜めていき、(2)スライスの長さが1のもの同士の要素を比べ、最小値を返す、というもの
- 時間計算量：O(n) （見積もり実行時間は、1ms）
- 空間計算量：O(n)

```Go
// Go

func firstUniqChar(s string) int {
	charIndices := make(map[rune][]int)
	for i, c := range s {
		charIndices[c] = append(charIndices[c], i)
	}

	ans := -1
	for _, indices := range charIndices {
		if len(indices) > 1 {
			continue
		}
		if ans == -1 {
			ans = indices[0]
		}
		ans = min(ans, indices[0])
	}

	return ans
}
```

### Step 2
#### 2a
- step1のコードを修正
- 答えが-1になる場合（ユニークな文字がない場合）を定数として定義
  - ansの初期値を-1に設定することに違和感があるから
- 二つ目のfor文の中の`if len(indices) > 1`を`if len(indices) != 1`に変更
  - 一つ目のfor文から任意のcに対してcharIndices[c]の長さは1以上であることが保証されているので動作は同じ
  - しかし、上記が保証されていることを読み解けないと`if len(indices) > 1`でない場合は`len(indices) == 1`であるということがわからない（認知負荷）

```Go
func firstUniqChar(s string) int {
	charIndices := make(map[rune][]int)

	for i, c := range s {
		charIndices[c] = append(charIndices[c], i)
	}

	const NoUniqueChar = -1
	ans := NoUniqueChar

	for _, indices := range charIndices {
		if len(indices) != 1 {
			continue
		}
		if ans == NoUniqueChar {
			ans = indices[0]
			continue
		}
		ans = min(ans, indices[0])
	}

	return ans
}
```

- 他の方の解答を読む時間

- https://github.com/rihib/leetcode/pull/18
- https://github.com/seal-azarashi/leetcode/pull/15
- お二方共非常に参考&勉強になった
- サロゲートペア・結合文字列・合字があったらどうしようと躊躇える感覚が大事

#### 2b
- 文字ごとの発生箇所をスライスとして保持するのではなく、発生回数を保持する方法
- step1のようにスライスとして保持すると、スライスの長さを拡張するオーバーヘッドで遅くなる + メモリ使用量も増える
- step1のようにansの初期値を-1(no unique characterの時の返り値)に設定すると、2個目のfor文の中の条件分岐が一つ増えるので、やめる

```Go
func firstUniqChar(s string) int {
	frequency := make(map[rune]int)
	for _, c := range s {
		frequency[c]++
	}

	for i, c := range s {
		if frequency[c] == 1 {
			return i
		}
	}

	return -1
}
```

#### 2c
- 入力条件が小文字アルファベットに限られていることを利用して、サイズ26の配列で出現回数を数える
- エラー処理もやってみた
  - 小文字アルファベットでない文字が含まれている場合、firstUniqChar関数を呼び出す前にあると思われる文字列をチェックする関数にバグがあるので、処理を止める
  - https://github.com/seal-azarashi/leetcode/pull/15/files#r1704435525 で「ユニークな文字がない場合」は関数呼び出し側でも参照したいと思われるので、グローバルなエラーとして定義
- 2bと比べると、
  - 長所：mapを作成するオーバーヘッドによる遅延がない。空間計算量がO(1)になる
  - 短所：入力条件がある程度厳しくないと使えない（日本語文字なども含まれるなら2bの方が適切）。入力条件が大小のアルファベット+数字とかならまだ2cの方が良い

```Go
// このコードはGo的なエラー処理をしたかったため、LeetCodeのシグネチャを変えて、返り値をintとerrorの二つにしています

type NoUniqueCharacterError struct{}

func (e *NoUniqueCharacterError) Error() string {
	return "no unique character found"
}

func firstUniqChar(s string) (int, error) {
	const AlphabetSize = 26
	var charFrequency [AlphabetSize]int

	for _, c := range s {
		if c < 'a' || c > 'z' {
			log.Fatal("invalid character found in the input")
			panic("unreachable")
		}

		charFrequency[c-'a']++
	}

	for i, c := range s {
		if charFrequency[c-'a'] == 1 {
			return i, nil
		}
	}

	return 0, &NoUniqueCharacterError{}
}
```

### Step 3
- 最終的に採用して方法は、入力条件に対する汎用性の高い2bの方法

```Go
const NoUniqueCharacter = -1

func firstUniqChar(s string) int {
	characterFrequency := make(map[rune]int)
	for _, c := range s {
		characterFrequency[c]++
	}

	for i, c := range s {
		if characterFrequency[c] == 1 {
			return i
		}
	}

	return NoUniqueCharacter
}
```

- 最後にGoのmapについて自分のためにメモ
  - runtime/map.goに実装が書かれている
  - goのmapはハッシュマップ
    - 8個のkey/valueを溜められるバケットの配列
  - ハッシュ値の下位ビット -> バケットを決める、上位ビット -> バケット内のスロットを決める
    - 近いハッシュ値に対して格納先が近くなると衝突を起こしやすくなるからこうしているのだろう
  - バケットがオーバーフローすると、新しいバケットを連結する
  - 各バケットの平均使用率が大体80%を超えるとバケット数が2倍されて再ハッシュされる
    - オーバーフローバケットが増えると要素追加の時間計算量がO(n)に近づき、パフォーマンスが悪化するため
  - 一つのバケット内のスロットは配列として実装されているため、連続したメモリアドレスに配置
  - 異なるバケット（連結バケットも含む）は連続していないため、キャッシュ効率は悪い

- 参考
  - https://github.com/rihib/leetcode/pull/18#issue-2467547324
  - https://zenn.dev/smartshopping/articles/5df9c3717e25bd
