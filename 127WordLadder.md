### Step 1
- 変換可能なwordを繋げた無向グラフを作成し、BFSで最短距離を探索する方法を思いついた
- 方針はすぐに思いついたが、いくつか実装を悩む点があり、かなり時間がかかった（1時間くらい？）
- 「beginWordがwordListに必ずしも含まれているわけではない」という条件で少し躓いた
- ローカルのテストケースで無限ループに陥った。wordに対して訪問済みマークをつけるのを忘れていたことが原因
- 実装後、Wrong Answerが出た。パスの長さの管理が適切にできていなかったことが原因
- 時間計算量：O(n^2) (nはwordListの要素数。本当は、beginWordの長さをmとしてO(n^2 m)だが、m <= 10なので無視できる)
- 空間計算量：O(n^2)

```Go
func ladderLength(beginWord string, endWord string, wordList []string) int {
	transformationGraph := initTransformationGraph(beginWord, wordList)
	return searchShortestPathToEndWord(beginWord, endWord, transformationGraph)
}

func initTransformationGraph(beginWord string, wordList []string) map[string][]string {
	transformationGraph := make(map[string][]string, len(wordList)+1)

	transformationGraph[beginWord] = []string{}
	for _, w1 := range wordList {
		if isTransformable(w1, beginWord) {
			transformationGraph[beginWord] = append(transformationGraph[beginWord], w1)
			transformationGraph[w1] = []string{beginWord}
			continue
		}
		transformationGraph[w1] = []string{}
	}

	for i := 0; i < len(wordList)-1; i++ {
		for j := i + 1; j < len(wordList); j++ {
			if isTransformable(wordList[i], wordList[j]) {
				transformationGraph[wordList[i]] = append(transformationGraph[wordList[i]], wordList[j])
				transformationGraph[wordList[j]] = append(transformationGraph[wordList[j]], wordList[i])
			}
		}
	}

	return transformationGraph
}

func searchShortestPathToEndWord(beginWord, endWord string, transformationGraph map[string][]string) int {
	type graphNode struct {
		word  string
		level int
	}

	checkedWords := make(map[string]struct{})
	wordQueue := []graphNode{{word: beginWord, level: 1}}

	for len(wordQueue) > 0 {
		first := wordQueue[0]
		wordQueue = wordQueue[1:]

		for _, w := range transformationGraph[first.word] {
			if w == endWord {
				return first.level + 1
			}
			if _, ok := checkedWords[w]; ok {
				continue
			}
			wordQueue = append(wordQueue, graphNode{word: w, level: first.level + 1})
			checkedWords[w] = struct{}{}
		}
	}

	return 0
}

func isTransformable(word1, word2 string) bool {
	differentCharacterCount := 0
	for i := 0; i < len(word1); i++ {
		if word1[i] != word2[i] {
			differentCharacterCount++
			if differentCharacterCount > 1 {
				return false
			}
		}
	}

	return differentCharacterCount == 1
}
```

### Step 2
- step1は無向グラフを完成させてから探索を始めたが、パフォーマンス改善のため、beginWordを始点としてグラフを作りながら探索することに
- ところが実行時間がstep1より1桁遅くなった
- 考えられる原因としては、グラフが疎だったから。つまり、wordListの要素数に対して、wordList[i]がtransformableな要素数が少ないので、内側のループで毎回wordListの全ての要素を調べることが非効率になってしまっている

```Go
type transformationGraphNode struct {
	word  string
	level int
}

func ladderLength(beginWord string, endWord string, wordList []string) int {
	wordQueue := []transformationGraphNode{{word: beginWord, level: 1}}
	visitedWords := make(map[string]struct{}, len(wordList))

	for len(wordQueue) > 0 {
		first := wordQueue[0]
		wordQueue = wordQueue[1:]

		for _, w := range wordList {
			if w == first.word {
				continue
			}
			if _, ok := visitedWords[w]; ok {
				continue
			}
			if !isTransformable(w, first.word) {
				continue
			}
			if w == endWord {
				return first.level + 1
			}
			wordQueue = append(wordQueue, transformationGraphNode{word: w, level: first.level + 1})
			visitedWords[w] = struct{}{}
		}
	}

	return 0
}

func isTransformable(word1, word2 string) bool {
	differentCharacterCount := 0
	for i := 0; i < len(word1); i++ {
		if word1[i] != word2[i] {
			differentCharacterCount++
			if differentCharacterCount > 1 {
				return false
			}
		}
	}

	return differentCharacterCount == 1
}
```

- ハミング距離：https://en.wikipedia.org/wiki/Hamming_distance
  - 同じ長さの2つの配列 or 文字列において、一方を何文字置換すればもう一方と等しくなるか。まさに今回計算する必要のある距離


- ToDo
  - ahayashiさんのプルリクを読む(https://github.com/hayashi-ay/leetcode/pull/42/files)
  - https://discord.com/channels/1084280443945353267/1200089668901937312/1215955040930631690
  - レーベンシュタイン距離を求める実装をする
  - 遅延評価(Lazy Evaluation)とは
