Class Search.Domain extends %Persistent {

// ��������� ��������� ��������� �������� �� ����������(������ ������ ��������, ������������� ������� ��������� ���������)

// do ##class(Search.Domain).%Build()

// ����������� ����� 5-10

// ����� �������� ������, ��������� �������� � ����� �������� ������ � ���������� ������

// do $system.iKnow.ListDomains()

/// ����� �������� ������, ���������� ��������� ������ � ���������� ��� �������
ClassMethod %Build() As %Status
{
	
	#Include %IKPublic
	
	ZNSPACE "DOCBOOK"
	
	// �������� ������ ��� ��������
	SET dname="DocSearch"  
	 	
   	IF (##class(%iKnow.Domain).Exists(dname)){
	   	SET domoref=##class(%iKnow.Domain).Open(dname)
    }
  	ELSE {	 
  		WRITE "The ",dname," domain does not exist",!
       	SET domoref=##class(%iKnow.Domain).%New(dname)
       	DO domoref.%Save()
    }	
  
   	//������������ ������� � �������
   	SET domId=domoref.Id
  	SET flister=##class(%iKnow.Source.SQL.Lister).%New(domId)
  	SET myloader=##class(%iKnow.Source.Loader).%New(domId)
  	
  	// ���������� �������
	
   	SET myquery="SELECT id,content, blockid, component->blockid As component_blockid, component->title As component_title, book->blockid As book_blockid, book->title As book_title FROM DocBook.block"
  	 	
  	SET idfld="id"
  	SET grpfld="id" // TODO: ���������� ��� �����
  	SET dataflds=$LB("content")
  	SET metaflds=$LB("id","blockid","component_blockid","component_title","book_blockid","book_title")
  	
  	//����������
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"id",$LB("="),$$$MDDTNUMBER)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"blockid",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_blockid",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"component_title",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_blockid",$LB("="),$$$MDDTSTRING)
  	SET val=##class(%iKnow.Queries.MetadataAPI).AddField(domId,"book_title",$LB("="),$$$MDDTSTRING)
  	
  	// ������ �������
  	SET stat=flister.AddListToBatch(myquery,idfld,grpfld,dataflds,metaflds)
      IF stat '= 1 {WRITE "The lister failed: ",$System.Status.DisplayError(stat) QUIT }
    // ������ ����������
    SET stat=myloader.ProcessBatch()
      IF stat '= 1 {
	      QUIT 
	       }
 
    //����������
    SET numSrcD=##class(%iKnow.Queries.SourceQAPI).GetCountByDomain(domId)
  	WRITE "The domain contains ",numSrcD," sources",!
  	SET numSentD=##class(%iKnow.Queries.SentenceQAPI).GetCountByDomain(domId)
  	WRITE "These sources contain ",numSentD," sentences",!!
  	
  	ZNSPACE "DOCSEARCH" 
  	 
  	s st = $$$OK
  	q st
}

/// ����� ������ �������� ���������. ���������� ������ ����, ����������� �������.
ClassMethod GetSimilar(SearchString) As %Status
{
	ZNSPACE "DOCBOOK"
	SET dname="DocSearch" 
	SET domoref=##class(%iKnow.Domain).Open(dname)
	SET domId=domoref.Id
	set resultArray = ##class(%DynamicArray).%New()
	set resultArray={}
	set SC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.Result, domId, SearchString)
	quit:$$$ISERR(SC) ""
	
	for i=0:1:10 {
		set �rd = $order(Result(i),1,Data)
		d resultArray.%Set(""_i,"similar")
		d resultArray.%Set(""_i,$li(Data,2))

	}
	
	w resultArray.%ToJSON()
	ZNSPACE "DOCSEARCH"
	q $$$OK
}

/*
�������� ��������� ������ � ������� DOCBOOK, � ����� DocBook.block ����� �����������
/// �������� �������� ������� iFind
Index contentInd On (content) As %iFind.Index.Basic(INDEXOPTION = 0, LOWER = 1, RANKERCLASS = 1);
*/
/// ��������� ���������� � ������ �� ������ ��� ������
ClassMethod SearchByText(text) As %Status
{
	//�������� ��������� ������� ��� �������� ����������� ������
	SET createquery = "CREATE TABLE temptable (idSQL INT,content VARCHAR(30000),link VARCHAR(10000),	frequency FLOAT,title VARCHAR(10000))"
  	SET createStatement = ##class(%SQL.Statement).%New()
  	SET createStatus = createStatement.%Prepare(createquery)
   	IF createStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(createStatus) QUIT}
  	SET createRset = createStatement.%Execute()
	ZNSPACE "DOCBOOK"
	
	// ��������� ����� ����� � ������� iFind � DocBook.block
	set tempArray = ##class(%ArrayOfDataTypes).%New()
	set count = 0	
	SET myquery = "SELECT id,content, component->blockid As link,book->title As title FROM DocBook.block WHERE %ID %FIND search_index(contentInd,'"_text_"',0)"
  	SET tStatement = ##class(%SQL.Statement).%New()
  	SET qStatus = tStatement.%Prepare(myquery)
   	IF qStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(qStatus) QUIT}
  	SET rset = tStatement.%Execute()
  	WHILE rset.%Next() {
	  	ZNSPACE "DOCSEARCH"
	  	set tempArray(count,0)= rset.id
	  	set tempArray(count,1) = ##class(Search.Parser).Parse(rset.content)
    	set tempArray(count,2) = rset.link
    	set tempArray(count,3) = ##class(Search.Parser).Frequency(tempArray(count,1),text)
    	set tempArray(count,4) = rset.title
    	set newquery ="insert into SQLUser.temptable(idSQL,content,link,frequency,title) VALUES(?,?,?,?,?)"
  		SET rset2 = ##class(%SQL.Statement).%ExecDirect(,.newquery,tempArray(count,0),tempArray(count,1),tempArray(count,2),tempArray(count,3),tempArray(count,4))
    	IF rset2.%SQLCODE'=0 {WRITE !,"1st ExecDirect SQLCODE=",rset2.%SQLCODE,!,rset2.%Message  QUIT}
  		s count = count + 1
    	ZNSPACE "DOCBOOK"
       } 
       
    // �������� ������ � ��������� ������� ��������������� �� �������
    ZNSPACE "DOCSEARCH"
   	
	s count = count - 1
	
	SET resultQuery = "SELECT JSON_OBJECT('idSQL':idSQL, 'content':content, 'link':link, 'frequency':frequency, 'title':title) FROM SQLUser.temptable ORDER BY frequency DESC"
  	SET Statement = ##class(%SQL.Statement).%New()
  	SET Status = Statement.%Prepare(resultQuery)
   	IF Status'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(Status) QUIT}
  	SET result = Statement.%Execute()
   	//WHILE result.%Next() {DO result.%Print(" ^ ")}

  	set countZap=0
  	w "{""sources"":["
    WHILE result.%Next() {
     DO result.%Print(" ^ ")
     if ((countZap'=count)) {
      w ","
      s countZap=countZap+1 
     }
    }
    w "]}"
    
	//������ ��������� �������
    SET dropquery = "drop table SQLUser.temptable"
  	SET dropStatement = ##class(%SQL.Statement).%New()
  	SET dropStatus = dropStatement.%Prepare(dropquery)
   	IF dropStatus'=1 {WRITE "%Prepare failed:" DO $System.Status.DisplayError(dropStatus) QUIT}
  	SET dropRset = dropStatement.%Execute()
	s st=$$$OK
	q st
}

Storage Default
{
<Data name="DomainDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Search.DomainD</DataLocation>
<DefaultData>DomainDefaultData</DefaultData>
<IdLocation>^Search.DomainD</IdLocation>
<IndexLocation>^Search.DomainI</IndexLocation>
<StreamLocation>^Search.DomainS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}