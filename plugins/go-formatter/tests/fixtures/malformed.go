package main

import    (
"fmt"
  "strings"
)

type   Person   struct{
Name   string
Age int
}

func    (p   *Person)   GetInfo()   string   {
return   fmt.Sprintf("%s is %d years old",p.Name,p.Age)
}

func    calculate(  a,b,c   int  )int{
result:=a+b+c
return     result
}

func main(){
numbers:=[]int{1,2,3,4,5}
doubled:=make([]int,len(numbers))

for   i,num:=range   numbers{
doubled[i]=num*2
}

person:=Person{Name:"Alice",Age:30}
info:=person.GetInfo()

if   true{
fmt.Println(  "This has bad spacing"  )
x:=1+2+3
y:=x*2
fmt.Println(strings.Join([]string{"a","b","c"},","))
}
}
