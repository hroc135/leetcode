### Step 1
- 最初に思いついた方法は、PythonのCounterのように一つのstringの中の文字の発生数を記録し、比べる方法
- しかし、mapのキーをmapにできず、頓挫。leetcodeで他の人の回答を見ることに
  - mapのキーはcomparableなものしか使えないということを勉強した。言われてみれば納得。Pythonだとhashableという表現
- 入力がすべてアルファベットであることを利用して、mapのキーを長さ26の配列にしている方法を発見。なるほど
- 時間計算量：O(mn) (m: str[i]の長さ, n: strの長さ)
  - mn = 100 * 10^4 = 10^6。つまり、Goだと最悪ケースで20msで実行可能。悪くない
- 空間計算量：O(n)

```Go
type charCnt [26]int

func groupAnagrams(strs []string) [][]string {
    charCntToStrs := make(map[charCnt][]string)
    for _, s := range strs {
        cnt := countChar(s)
        charCntToStrs[cnt] = append(charCntToStrs[cnt], s)
    }

    ans := [][]string{}
    for _, v := range charCntToStrs {
        ans = append(ans, v)
    }
    return ans
}

func countChar(str string) charCnt {
    var cnt charCnt
    for i := 0; i < len(str); i++ {
        cnt[str[i] - 'a']++
    }
    return cnt
}
```

### Step 2
- まずは自分の解答をブラッシュアップ
- countChar関数の中の`cnt[str[i] - 'a']++`がわかりにくいなと思った。
なぜわかりにくいのかを分析すると、1行で二つの質の違う処理をしているからだろう
- ということで2行に分け、補助的なコメントもつけることに
- charCntToStrsという名前だと末尾のStrsの部分が引数のstrsと一緒で混乱を引き起こすかもしれないのでcharCntToStringsとすることに
  - でも相変わらず名前が微妙な気がする

```Go
type charCnt [26]int

func groupAnagrams(strs []string) [][]string {
    charCntToStrings := make(map[charCnt][]string)
    for _, s := range strs {
        cnt := countChar(s)
        charCntToStrings[cnt] = append(charCntToStrings[cnt], s)
    }

    anagramGroups := [][]string{}
    for _, v := range charCntToStrings {
        anagramGroups = append(anagramGroups, v)
    }
    return anagramGroups
}

func countChar(str string) charCnt {
    var cnt charCnt
    for i := 0; i < len(str); i++ {
        idx := str[i] - 'a' // 'a' = 97, 'b' = 98, ...
        cnt[idx]++
    }
    return cnt
}
```

- 上記解答の弱点は入力がアルファベットであるという条件に依存して、配列の長さを26に設定できている点だと思う
  - もし入力文字に条件がなく、@,[,/なども含まれ、はたまた'日'さえも含まれるなら使えない解放
  - 配列の長さをめちゃくちゃ大きくすればできなくはないが、空間計算量が大きくなってしまう
- 入力文字に条件がないなら、strs[i]をそれぞれソートし、ソート後の結果を比較して分類する
- 時間計算量：O(nmlogm) (m: str[i]の長さ, n: strの長さ)
  - ただし、今回はmの最大値が高々100 ≒ 2^7なので、step1の方法のO(mn)と比べてそこまで悪くはない
  - leetcodeの（当てにならない）実行時間も大体同じ
- 空間計算量：O(n)
  - step1の方法は常にキーに長さ26の配列を持っていたが、今回は長さmになるので、最悪の場合は長さ100のstringを持つことになってしまう
- 総じて、パフォーマンスはstep1の文字数カウントの方法の方が若干良いと言える
- ただし、先述の通り、各文字列をソートする方法は、入力がアルファベットに限らず色々な条件が考えられる場合に有効
- 他の人のコードを見ていたらmapの変数名でvalueを表す部分にangramという単語を使っており、関数名もgroupAnagramsなので採用

```Go
func groupAnagrams(strs []string) [][]string {
    sortedToAnagrams := make(map[string][]string)
    for _, s := range strs {
        sorted := sortStr(s)
        sortedToAnagrams[sorted] = append(sortedToAnagrams[sorted], s)
    }

    anagramGroups := [][]string{}
    for _, anagrams := range sortedToAnagrams {
        anagramGroups = append(anagramGroups, anagrams)
    }
    return anagramGroups
}

func sortStr(str string) string {
    chars := []byte(str)
    slices.SortFunc(chars, func(a, b byte) int {
        return int(a) - int(b)
    })
    return string(chars)
}
```

### Step 3
- どのやり方を採用するか迷ったが、3回も書くのならより覚えたい方を書こうということで、入力条件に左右されずに使える、ソート文字列をキーに使う方法で書くことに
- 変更箇所はsortStrという変数名 -> sortCharsOfStr
  - sortStrだとstringのリストを辞書順にソートするというふうにも捉えられかねないと思い、stringに含まれるcharをソートするという意味を含めた変数名にした

```Go
func groupAnagrams(strs []string) [][]string {
    sortedToAnagrams := make(map[string][]string)
    for _, s := range strs {
        sorted := sortCharsOfStr(s)
        sortedToAnagrams[sorted] = append(sortedToAnagrams[sorted], s)
    }

    anagramGroups := [][]string{}
    for _, v := range sortedToAnagrams {
        anagramGroups = append(anagramGroups, v)
    }
    return anagramGroups
}

func sortCharsOfStr(str string) string {
    chars := []byte(str)
    slices.SortFunc(chars, func(a, b byte) int {
        return int(a) - int(b)
    })
    return string(chars)
}
```
