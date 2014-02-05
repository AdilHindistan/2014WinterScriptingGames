#set permissions
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"


$acl =get-acl "$FiltersKey\.pdf"
$rule=new-object system.security.accesscontrol.registryaccessrule "NETWORK SERVICE","ReadKey",$inherit,$propagation,"Allow"
$acl.addaccessrule($rule)
$acl|set-acl
get-acl -path "$FiltersKey\.pdf"|fl

$acl1 =get-acl "$CLSIDKey\$PDFGuid"
$rule1=new-object system.security.accesscontrol.registryaccessrule "NETWORK SERVICE","ReadKey",$inherit,$propagation,"Allow"
$acl1.addaccessrule($rule1)
$acl1|set-acl
get-acl -path "$CLSIDKey\$PDFGuid"|fl