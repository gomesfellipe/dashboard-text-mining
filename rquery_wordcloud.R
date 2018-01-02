#++++++++++++++++++++++++++++++++++
# rquery.wordcloud() versao inicial retirada:
# - http://www.sthda.com
#+++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++
# Remover acentos
rm_accent <- function(str,pattern="all") {
  # Rotinas e funções úteis V 1.0
  # rm.accent - REMOVE ACENTOS DE PALAVRAS
  # Função que tira todos os acentos e pontuações de um vetor de strings.
  # Parâmetros:
  # str - vetor de strings que terão seus acentos retirados.
  # patterns - vetor de strings com um ou mais elementos indicando quais acentos deverão ser retirados.
  #            Para indicar quais acentos deverão ser retirados, um vetor com os símbolos deverão ser passados.
  #            Exemplo: pattern = c("´", "^") retirará os acentos agudos e circunflexos apenas.
  #            Outras palavras aceitas: "all" (retira todos os acentos, que são "´", "`", "^", "~", "¨", "ç")
  if(!is.character(str))
    str <- as.character(str)
  
  pattern <- unique(pattern)
  
  if(any(pattern=="Ç"))
    pattern[pattern=="Ç"] <- "ç"
  
  symbols <- c(
    acute = "áéíóúÁÉÍÓÚýÝ",
    grave = "àèìòùÀÈÌÒÙ",
    circunflex = "âêîôûÂÊÎÔÛ",
    tilde = "ãõÃÕñÑ",
    umlaut = "äëïöüÄËÏÖÜÿ",
    cedil = "çÇ"
  )
  
  nudeSymbols <- c(
    acute = "aeiouAEIOUyY",
    grave = "aeiouAEIOU",
    circunflex = "aeiouAEIOU",
    tilde = "aoAOnN",
    umlaut = "aeiouAEIOUy",
    cedil = "cC"
  )
  
  accentTypes <- c("´","`","^","~","¨","ç")
  
  if(any(c("all","al","a","todos","t","to","tod","todo")%in%pattern)) # opcao retirar todos
    return(chartr(paste(symbols, collapse=""), paste(nudeSymbols, collapse=""), str))
  
  for(i in which(accentTypes%in%pattern))
    str <- chartr(symbols[i],nudeSymbols[i], str)
  
  return(str)
}
#++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++
# Download e analise de webpage
html_to_text<-function(url){
  library(RCurl)
  library(XML)
  # download html
  html.doc <- getURL(url)  
  #convert to plain text
  doc = htmlParse(html.doc, asText=TRUE)
  # "//text()" returns all text outside of HTML tags.
  # We also don’t want text such as style and script codes
  text <- xpathSApply(doc, "//text()[not(ancestor::script)][not(ancestor::style)][not(ancestor::noscript)][not(ancestor::form)]", xmlValue)
  # Format text vector into one character string
  return(paste(text, collapse = " "))
}
#++++++++++++++++++++++

# #++++++++++++++++++++++
# # Remove alguns plurais
# remove_plural=function(x){
#   for(i in 1:length(x)){
#     x[i]=str_replace_all(x[i], "as$", "a")
#     x[i]=str_replace_all(x[i], "es$", "e")
#     x[i]=str_replace_all(x[i], "os$", "o")
#     x[i]=str_replace_all(x[i], "us$", "u")
#     x[i]=str_replace_all(x[i], "oes$", "ao")
#     return(x)
#     }
# }

#++++++++++++++++++++++

# x : character string (plain text, web url, txt file path)
# type : specify whether x is a plain text, a web page url or a file path
# lang : the language of the text
# excludeWords : a vector of words to exclude from the text
# textStemming : reduces words to their root form
# colorPalette : the name of color palette taken from RColorBrewer package, 
# or a color name, or a color code
# min.freq : words with frequency below min.freq will not be plotted
# max.words : Maximum number of words to be plotted. least frequent terms dropped
# value returned by the function : a list(tdm, freqTable)
#install.packages(c("tm", "SnowballC", "wordcloud", "RColorBrewer", "RCurl", "XML")

rquery.wordcloud <- function(x, type=c("text", "url", "file"), 
                             lang="portuguese", excludeWords=NULL, 
                             textStemming=FALSE,  colorPalette="Dark2",
                             min.freq=3, max.words=200,rm.accent=F,tf.idf=F,print=T,ngrams=0)
{ 
  library("tm")
  library("SnowballC")
  library("wordcloud")
  library("RColorBrewer") 
  library("lexiconPT")
  
  if(type[1]=="file") text <- readLines(x)
  else if(type[1]=="url") text <- html_to_text(x)
  else if(type[1]=="text") text <- x
  
  #limpeza
  text=cleanTweets(text)
  
  #Remover acentos
  if(rm.accent==T){
    text=rm_accent(text)
  }
  
  # Plural:
  # text%>%
  #   str_replace_all("as", "a")%>%
  #   str_replace_all("es", "e")%>%
  #   str_replace_all("os", "o")%>%
  #   str_replace_all("us", "u")%>%
  #   str_replace_all("oes", "ao")
  
  # Load the text as a corpus
  docs <- Corpus(DataframeSource(as.data.frame(text))) #Para grams
  if(textStemming) docs <- Corpus(VectorSource(text))  #Para stemming
  
  # Convert the text to lower case
  docs <- tm_map(docs, content_transformer(tolower))
  # Remove numbers
  docs <- tm_map(docs, removeNumbers)
  # Remove stopwords for the language 
  docs <- tm_map(docs, removeWords, stopwords(lang))
  # Remove punctuations
  docs <- tm_map(docs, removePunctuation)
  # Eliminate extra white spaces
  docs <- tm_map(docs, stripWhitespace)
  # Remove your own stopwords
  if(!is.null(excludeWords)) 
    docs <- tm_map(docs, removeWords, excludeWords) 
  # Text stemming
  if(textStemming) docs <- tm_map(docs, stemDocument,language=lang)
  
  # Create term-document matrix
  tdm <- TermDocumentMatrix(docs)
  
  #Se tf.idf for verdadeiro:
  if(tf.idf==T){
    tdm=weightTfIdf(tdm,normalize=T)
  }
  
  #Se Ngram=bigrams:
  if(ngrams!=0){
    library("rJava")
    library("RWeka")
    Tokenizer <- function(x) NGramTokenizer(x, Weka_control(min = ngrams, max = ngrams))
    tdm = TermDocumentMatrix(docs,control = list(tokenize = Tokenizer))
  }
  
  #Criando matriz para retornar
  m <- as.matrix(tdm)
  v <- sort(rowSums(m),decreasing=TRUE)
  d <- data.frame(word = names(v),freq=v)
  
  if(print==T){
    # check the color palette name 
    if(colorPalette!="sentiment"){
      if(!colorPalette %in% rownames(brewer.pal.info)){ 
        colors = colorPalette
        # Plot the word cloud
        set.seed(1234)
        wordcloud(d$word,d$freq, min.freq=min.freq, max.words=max.words,
                  random.order=FALSE, rot.per=0.35, 
                  use.r.layout=FALSE, colors=colors)
      }else{
        colors = brewer.pal(8, colorPalette)
        # Plot the word cloud
        set.seed(1234)
        wordcloud(d$word,d$freq, min.freq=min.freq, max.words=max.words,
                  random.order=FALSE, rot.per=0.35, 
                  use.r.layout=FALSE, colors=colors)
      }
      return(list(tdm=tdm, freqTable = d)) 
    }
    
    if(colorPalette=="sentiment"){
      #data("sentiLex_lem_PT02")
      sentiLex_lem_PT02 <- readr::read_csv("sentimentos.csv")
      
      #Selecionando as palavras (seus radicais) e sua polaridade
      dicionary=data.frame(cbind(sentiLex_lem_PT02$term,sentiLex_lem_PT02$polarity))
      matriz=d
      #Arrumando nome das bases de dados2: (Colocar nomes iguais para words)
      names(dicionary)=c("words", "sentiment")
      names(matriz)=c("words", "freq")
      
      #Transformando palavras em character:
      dicionary$words=as.character(dicionary$words)
      matriz$words=as.character(matriz$words)
      
      if(textStemming){ dicionary$words <- wordStem(dicionary$words,language = "portuguese")}
      
      dicionary=dicionary[ dicionary$sentiment==1 | dicionary$sentiment==0 | dicionary$sentiment==-1, ]
      dicionary$sentiment=as.factor(dicionary$sentiment)
      #Alterando o nome dos sentimentos:
      levels(dicionary$sentiment)=c("Negativo","Neutro","Positivo")
      
      #Join das palavras do documento com o dicionario ntivo do R
      sentimentos=data.frame(matriz) %>%
        left_join(data.frame(dicionary),by="words") %>%
        select(words,sentiment,freq)%>%
        distinct(words,.keep_all = T)
      
      rownames(d)=d$word
      #Neutro para palavras fora do dicionario
      sentimentos$sentiment[is.na(sentimentos$sentiment)]="Neutro"
      
      #Criando coluna de cores para cada sentimento
      sentimentos$col=c(ifelse(sentimentos$sentiment=="Neutro","gray80",ifelse(sentimentos$sentiment=="Positivo","blue","red")))
      ##########################################
      # Plot the word cloud
      set.seed(1234)
      wordcloud(sentimentos$words,freq = sentimentos$freq, min.freq=min.freq, max.words=max.words,
                random.order=FALSE, rot.per=0.35, 
                use.r.layout=FALSE, colors = sentimentos$col,ordered.colors = T)
      return(list(tdm=tdm, freqTable = sentimentos))
    }
  }else{
    return(list(tdm=tdm, freqTable = d))}
  
  # invisible(list(tdm=tdm, freqTable = d))
}
