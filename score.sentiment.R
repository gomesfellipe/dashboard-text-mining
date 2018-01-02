score.sentiment = function(words, pos.words, neg.words)
{
  require(plyr)
  require(stringr)
  
  scores = laply(words, function(tweet, pos.words, neg.words) {
    
    word.list = str_split(tweet, '\\s+') # splits the words by word in a list
    
    words = unlist(word.list) # turns the list into vector
    
    pos.matches = match(words, pos.words) ## returns matching 
    #values for words from list 
    neg.matches = match(words, neg.words)
    
    pos.matches = !is.na(pos.matches) ## converts matching values to true of false
    neg.matches = !is.na(neg.matches)
    
    score = sum(pos.matches) - sum(neg.matches) # true and false are 
    #treated as 1 and 0 so they can be added
    
    return(score)
    
  }, pos.words, neg.words )
  
  scores.df = data.frame(score=scores, text=words)
  
  return(scores.df)
}
