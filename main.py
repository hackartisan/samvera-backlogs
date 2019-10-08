from sklearn.datasets import load_files
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer

data_bunch = load_files('data/open_issues')

# stop words: max_df can be set to a value in the range [0.7, 1.0) to automatically detect and filter stop words based on intra corpus document frequency of terms.
# TODO: look at ngram_range?

count_vect = CountVectorizer()
vectors = count_vect.fit_transform(data_bunch.data)

tfidf_transformer = TfidfTransformer()
vectors_tfidf = tfidf_transformer.fit_transform(vectors)
