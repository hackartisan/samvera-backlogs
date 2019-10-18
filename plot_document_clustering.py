# Author: Peter Prettenhofer <peter.prettenhofer@gmail.com>
#         Lars Buitinck
# License: BSD 3 clause
from sklearn.datasets import load_files
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.feature_extraction.text import HashingVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import Normalizer
from sklearn import metrics

from sklearn.cluster import KMeans, MiniBatchKMeans

import logging
from optparse import OptionParser
import sys
from time import time

import numpy as np

from nltk import download
from nltk import word_tokenize
from nltk.stem.porter import PorterStemmer
from nltk.stem import WordNetLemmatizer
download('popular')

import string
import re
import collections

# Display progress logs on stdout
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(levelname)s %(message)s')

# parse commandline arguments
op = OptionParser()
op.add_option("--n", type="int", dest="n_clusters", default=8)
op.add_option("--files", dest="files_path", default="./data/open_issues/clean")
op.add_option("--lsa",
              dest="n_components", type="int",
              help="Preprocess documents with latent semantic analysis.")
op.add_option("--no-minibatch",
              action="store_false", dest="minibatch", default=False,
              help="Use ordinary k-means algorithm (in batch mode).")
op.add_option("--no-idf",
              action="store_false", dest="use_idf", default=True,
              help="Disable Inverse Document Frequency feature weighting.")
op.add_option("--use-hashing",
              action="store_true", default=False,
              help="Use a hashing feature vectorizer")
op.add_option("--n-features", type=int, default=10000,
              help="Maximum number of features (dimensions)"
                   " to extract from text.")
op.add_option("--verbose",
              action="store_true", dest="verbose", default=False,
              help="Print progress reports inside k-means algorithm.")

#print(__doc__)
#op.print_help()

def is_interactive():
    return not hasattr(sys.modules['__main__'], '__file__')


# work-around for Jupyter notebook and IPython console
argv = [] if is_interactive() else sys.argv[1:]
(opts, args) = op.parse_args(argv)
if len(args) > 0:
    op.error("this script takes no arguments.")
    sys.exit(1)


# #############################################################################
# local processing rules

def stem_tokens(tokens, stemmer):
    stemmed = []
    for item in tokens:
        stemmed.append(stemmer.lemmatize(item))
    return stemmed

def tokenize(text):
    stemmer = WordNetLemmatizer()
    text = "".join([ch for ch in text if ch not in string.punctuation])
    tokens = word_tokenize(text)
    stems = stem_tokens(tokens, stemmer)
    return stems

base_stopwords = ["a", "about", "above", "after", "again", "against", "ain", "all",
        "am", "an", "and", "any", "are", "aren", "aren't", "as", "at", "be",
        "because", "been", "before", "being", "below", "between", "both", "but",
        "by", "can", "couldn", "couldn't", "d", "did", "didn", "didn't", "do",
        "does", "doesn", "doesn't", "doing", "don", "don't", "down", "during",
        "each", "few", "for", "from", "further", "had", "hadn", "hadn't", "has",
        "hasn", "hasn't", "have", "haven", "haven't", "having", "he", "her",
        "here", "hers", "herself", "him", "himself", "his", "how", "i", "if",
        "in", "into", "is", "isn", "isn't", "it", "it's", "its", "itself",
        "just", "ll", "let", "m", "ma", "me", "mightn", "mightn't", "more",
        "most", "mustn", "mustn't", "my", "myself", "needn", "needn't", "no",
        "nor", "not", "now", "o", "of", "off", "on", "once", "only", "or",
        "other", "our", "ours", "ourselves", "out", "over", "own", "re", "s",
        "same", "shan", "shan't", "she", "she's", "should", "should've",
        "shouldn", "shouldn't", "so", "some", "such", "t", "than", "that",
        "that'll", "the", "their", "theirs", "them", "themselves", "then",
        "there", "these", "they", "this", "those", "through", "to", "too",
        "under", "until", "up", "ve", "very", "was", "wasn", "wasn't", "we",
        "were", "weren", "weren't", "what", "when", "where", "which", "while",
        "who", "whom", "why", "will", "with", "won", "won't", "wouldn",
        "wouldn't", "y", "you", "you'd", "you'll", "you're", "you've", "your",
        "yours", "yourself", "yourselves", "could", "he'd", "he'll", "he's",
        "here's", "how's", "i'd", "i'll", "i'm", "i've", "let's", "ought",
        "she'd", "she'll", "that's", "there's", "they'd", "they'll", "they're",
        "they've", "we'd", "we'll", "we're", "we've", "what's", "when's",
        "where's", "who's", "why's", "would"]
corpus_stopwords = ["princeton", "pudl", "scholar", "uc", "scholar_uc_legacy",
        "uclibs", "figgy", "psu", "scholarsphere", "hydrus", "acceptance",
        "criteria"]
stemmed_stopwords = ['abov', 'accept', 'ani', 'arent', 'becaus', 'befor',
        'couldnt', 'didnt', 'doe', 'doesnt', 'dont', 'dure', 'figgi', 'ha',
        'hadnt', 'hasnt', 'havent', 'hed', 'hell', 'hi', 'hydru', 'id', 'ill',
        'im', 'isnt', 'ive', 'mightnt', 'mustnt', 'neednt', 'onc', 'onli',
        'ourselv', 'scholarspher', 'scholaruclegaci', 'shant', 'shed', 'shell',
        'shouldnt', 'shouldv', 'thatll', 'themselv', 'theyd', 'theyll', 'theyr',
        'theyv', 'thi', 'uclib', 'veri', 'wa', 'wasnt', 'wed', 'well', 'werent',
        'weve', 'whi', 'wont', 'wouldnt', 'youd', 'youll', 'yourselv', 'youv', 'becau', 'scholarsph']
lemmatized_stopwords = ['criterion', 'hows', 'scholaruclegacy', 'shes', 'shouldve', 'thats', 'theyre', 'theyve', 'whats', 'whens', 'wheres', 'youre', 'youve']
stopwords = base_stopwords + corpus_stopwords + stemmed_stopwords + lemmatized_stopwords


# #############################################################################
# main

print("Loading open issues:")

dataset = load_files("./data/open_issues/clean")
dataset = load_files(opts.files_path)
# TODO: Shuffle the data

print("%d documents" % len(dataset.data))
print()

#labels = dataset.target

print("Extracting features from the training dataset "
      "using a sparse vectorizer")
t0 = time()
if opts.use_hashing:
    if opts.use_idf:
        # Perform an IDF normalization on the output of HashingVectorizer
        hasher = HashingVectorizer(n_features=opts.n_features,
                                   stop_words='english', alternate_sign=False,
                                   norm=None, binary=False)
        vectorizer = make_pipeline(hasher, TfidfTransformer())
    else:
        vectorizer = HashingVectorizer(n_features=opts.n_features,
                                       stop_words='english',
                                       alternate_sign=False, norm='l2',
                                       binary=False)
else:
    vectorizer = TfidfVectorizer(max_df=0.5, max_features=opts.n_features,
                                 min_df=2, stop_words=stopwords,
                                 use_idf=opts.use_idf,
                                 tokenizer=tokenize)
X = vectorizer.fit_transform(dataset.data)

print("done in %fs" % (time() - t0))
print("n_samples: %d, n_features: %d" % X.shape)
print()

if opts.n_components:
    print("Performing dimensionality reduction using LSA")
    t0 = time()
    # Vectorizer results are normalized, which makes KMeans behave as
    # spherical k-means for better results. Since LSA/SVD results are
    # not normalized, we have to redo the normalization.
    svd = TruncatedSVD(opts.n_components)
    normalizer = Normalizer(copy=False)
    lsa = make_pipeline(svd, normalizer)

    X = lsa.fit_transform(X)

    print("done in %fs" % (time() - t0))

    explained_variance = svd.explained_variance_ratio_.sum()
    print("Explained variance of the SVD step: {}%".format(
        int(explained_variance * 100)))

    print()


# #############################################################################
# Do the actual clustering

if opts.minibatch:
    km = MiniBatchKMeans(n_clusters=opts.n_clusters, init='k-means++', n_init=1,
                         init_size=1000, batch_size=1000, verbose=opts.verbose)
else:
    km = KMeans(n_clusters=opts.n_clusters, init='k-means++', max_iter=100, n_init=10,
                verbose=opts.verbose)

print("Clustering sparse data with %s" % km)
t0 = time()
km.fit(X)
print("done in %0.3fs" % (time() - t0))
print()

# These metrics are irrelevant to the clustering we're doing
# They depend on tuning to a training set where you know your categories ahead
# of time

#print("Homogeneity: %0.3f" % metrics.homogeneity_score(labels, km.labels_))
#print("Completeness: %0.3f" % metrics.completeness_score(labels, km.labels_))
#print("V-measure: %0.3f" % metrics.v_measure_score(labels, km.labels_))
#print("Adjusted Rand-Index: %.3f"
#      % metrics.adjusted_rand_score(labels, km.labels_))
#print("Silhouette Coefficient: %0.3f"
#      % metrics.silhouette_score(X, km.labels_, sample_size=1000))
#
#print()


def parse_filename(path):
    fn = path.rpartition("/")[2]
    pattern = '(.*)_(.*)_issue_(.*).txt'
    result = re.match(pattern, fn)
    if result is None:
        return ['None', 'None']
    repository = f'{result.group(1)}/{result.group(2)}'
    issue_number = result.group(3)
    return(repository, issue_number)


if not opts.use_hashing:
    print("Top terms per cluster:")

    tuples = zip(km.labels_, dataset.filenames)
    cluster_sets = collections.defaultdict(list)
    for t in tuples:
        cluster_sets[t[0]].append(t[1])

    # key: cluster_number, val: list of dicts
    new_cluster_dict = collections.defaultdict(list)
    for cluster_number, filenames in cluster_sets.items():
        # key: repository name, val: list of issue numbers
        issues_list = collections.defaultdict(list)
        for fn in filenames:
            repository, issue_number = parse_filename(fn)
            issues_list[repository].append(issue_number)
        new_cluster_dict[cluster_number] = issues_list

    if opts.n_components:
        original_space_centroids = svd.inverse_transform(km.cluster_centers_)
        order_centroids = original_space_centroids.argsort()[:, ::-1]
    else:
        order_centroids = km.cluster_centers_.argsort()[:, ::-1]

    terms = vectorizer.get_feature_names()
    # print full report
    for i in range(opts.n_clusters):
        print("Cluster %d:" % i, end='')
        for ind in order_centroids[i, :10]:
            print(' %s' % terms[ind], end='')
        print()
        for repository, issues_list in new_cluster_dict[i].items():
            print(f'  {repository} ({len(issues_list)} issues): {", ".join(issues_list)}')
        print()


    # print summary like
    # Cluster 0:
    #   here are all the words in the cluster
    #   258 issues in 7 repositories

    # i is the cluster number
    for i in range(opts.n_clusters):
        print("Cluster %d:" % i, end='\n')
        print(' ', end='')
        for ind in order_centroids[i, :10]:
            print(f' %s' % terms[ind], end='')
        # h is a dict keys: repo strings, vals: lists of issue #s
        issues_per_cluster = 0
        for l in new_cluster_dict[i].values():
            issues_per_cluster += len(l)
        print()
        print(f'  {issues_per_cluster} issues in {len(new_cluster_dict[i].keys())} repositories')
        print()

