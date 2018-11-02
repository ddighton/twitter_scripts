##code adapted from https://pushpullfork.com/mining-twitter-data-tidy-text-tags/

###load needed libraries
library(tidyverse)
library(tidytext)
library(lubridate)
library(stringr)
library(httr)
library(scales)


###load tweets

tweets_csv <- 'PATH/TO/MERGE/FILE'  ###this merge file comes from the output of the Twitter2r script


###create matrix

tweets <- read_csv(tweets_csv) %>%
mutate(date = mdy(paste(substring(created_at, 5, 10), substring(created_at, 27 ,30))))

source_text <- '#gentrification'
minimum_occurrences <- 5 # minimum number of occurrences to include in output


### remove stopwords and non-alpha characters

reg_words <- "([^A-Za-z_\\d#@']|'(?![A-Za-z_\\d#@]))"
tidy_tweets <- tweets %>%
  mutate(text = str_replace_all(tweet, "https://t.co/[A-Za-z\\d]+|http://[A-Za-z\\d]+|&amp;|&lt;|&gt;|RT|https", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg_words) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]"))

  #filter(!str_detect(tweet, "^RT")) %>% ###use only if you want to remove retweets

reg_words <- "([^A-Za-z_\\d#@']|'(?![A-Za-z_\\d#@]))"
tidy_tweets <- tweets %>% ##change to correct source
  mutate(tweet = str_replace_all(tweet, "https://t.co/[A-Za-z\\d]+|http://[A-Za-z\\d]+|&amp;|&lt;|&gt|https", "")) %>%  ### add strings with space here to remove other noise
  unnest_tokens(word, body, token = "regex", pattern = reg_words) %>%
  filter(!word %in% stopwords$word,
         str_detect(word, "[a-z]")) ###stop_words with certain words removed

### get word count

tidy_tweets %>%
  count(word, sort=TRUE) %>%
  filter(n > 150) %>%
  mutate(word = reorder(word, n))


###write count to csv

write_csv(tidy_tweets, '/Users/brn5/tidy_tweets.csv' ##‘name/of/file.csv’)

###remove hashtags and get word count
tidy_tweets %>%
  count(word, sort=TRUE) %>%
  filter(substr(word, 1, 1) != '#', # omit hashtags
         substr(word, 1, 1) != '@') %>% # omit Twitter handles
  mutate(word = reorder(word, n))


###create wordcount

word_count <- tidy_tweets %>%
  count(word, sort=TRUE) %>%
  filter(substr(word, 1, 1) != '#', # omit hashtags
         substr(word, 1, 1) != '@') %>% # omit Twitter handles
  mutate(word = reorder(word, n))


### Turn off scientic notations

options(scipen=999)

###create word count graph

tidy_tweets %>%
  count(word, sort=TRUE) %>%
  filter(substr(word, 1, 1) != '#', # omit hashtags
         substr(word, 1, 1) != '@', # omit Twitter handles
         n > 7500) %>% # only most common words
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = word)) +
  geom_bar(stat = 'identity') +
  xlab(NULL) +
  ylab(paste('Word count (since ',
             min(tidy_tweets$created_at),
             ')', sep = '')) +
  ggtitle(paste('Most common words in Tweets')) +
  theme(legend.position="none") +
  coord_flip()

### create bigrams

tidy_bigrams <- tweets %>%
  filter(!str_detect(tweet, "^RT")) %>%
  mutate(text = str_replace_all(tweet, "https://t.co/[A-Za-z\\d]+|http://[A-Za-z\\d]+|&amp;|&lt;|&gt;|RT|https", "")) %>%
  unnest_tokens(word, text, token = "regex", pattern = reg_words) %>%
  mutate(next_word = lead(word)) %>%
  filter(!word %in% stop_words$word, # remove stop words
         !next_word %in% stop_words$word, # remove stop words
         substr(word, 1, 1) != '@', # remove user handles to protect privacy
         substr(next_word, 1, 1) != '@', # remove user handles to protect privacy
         substr(word, 1, 1) != '#', # remove hashtags
         substr(next_word, 1, 1) != '#',
         str_detect(word, "[a-z]"), # remove words containing ony numbers or symbols
         str_detect(next_word, "[a-z]")) %>% # remove words containing ony numbers or symbols
  filter(id == lead(id)) %>% # needed to ensure bigrams to cross from one tweet into the next
  unite(bigram, word, next_word, sep = ' ') %>%
 select(bigram, screen_name, created_at, id) 


### remove noisy bigrams

tidy_bigrams <- tidy_bigrams[!tidy_bigrams$bigram == "mirror king", ]


###create bigram graph

#tidy_bigrams %>%
#    count(bigram, sort=TRUE) %>%
#    filter(n >= 50) %>%
#    mutate(bigram = reorder(bigram, n)) %>%
#    ggplot(aes(bigram, n, fill = bigram)) +
#    geom_bar(stat = 'identity') +
#    xlab(NULL) +
#    ylab(paste('Bigram count Feb 6 - April 6 2017'))  +
#    ggtitle(paste('Most common bigrams in tweets containing', source_text)) +
#    theme(legend.position="none") +
#    coord_flip()


###use if date is properly set when reading in csv

tidy_bigrams %>%
    count(bigram, sort=TRUE) %>%
    filter(n >= 15) %>%
    mutate(bigram = reorder(bigram, n)) %>%
    ggplot(aes(bigram, n, fill = bigram)) +
    geom_bar(stat = 'identity') +
    xlab(NULL) +
    ylab(paste('bigram count ',
               min(gsub("[0-9]*:[0-9]*|0000 |^[A-z]* |[+]|", "", tidy_tweets$created_at)), ' - ', max(gsub("[0-9]*:[0-9]*|0000 |^[A-z]* |[+]|", "", tidy_tweets$created_at))
               , sep = '')) +
    ggtitle(paste('Most common bigrams in tweets containing', source_text)) +
    theme(legend.position="none") +
    coord_flip()