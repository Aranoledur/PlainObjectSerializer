#!/usr/bin/python
from __future__ import print_function
import sys, getopt, os
import xml.etree.ElementTree

def main(argv):
    inputfile = ''
    outputdir = ''
    try:
        opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile> -o <outputdir>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <inputfile> -o <outputdir>', end="")
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-o", "--ofile"):
            outputdir = arg
    print ('Input file is "', inputfile)

    e = xml.etree.ElementTree.parse(inputfile).getroot()

    directory = "./Code/Cache" if not outputdir else outputdir
    if not os.path.exists(directory):
        os.makedirs(directory)

    filelist = [ f for f in os.listdir(directory + "/") ]
    for f in filelist:
        os.remove(directory + "/" + f)


    for atype in e.findall('entity'):
        className = atype.get('name')
        plainObjectClass = className.replace("CD", "")
        filename = className + ".swift"

        f = open(directory + "/" + className + "+CoreDataClass" + ".swift",'w')

        print("import Foundation\nimport CoreData\nimport PlainObjectSerializer", file=f)
        print ("\n@objc(", className, ")", sep="", file=f)
        print ("public class", className, ": NSManagedObject, PlainObjectSerializer, CoreDataFetchable {\n", file=f)
        print ("\tpublic static let entityName: String = String(describing: ", className, ".self)\n", sep="", file=f)
        print ("\ttypealias T = ", plainObjectClass, "\n", sep="", file=f)

    #fromPlainObject
        print ("\tpublic func fillFromPlainObject(_ plainObject: T) {", file=f)
        print ("\n\t\tguard let context = managedObjectContext else {\n\t\t\treturn\n\t\t}\n", file=f)
        for aAttribute in atype.findall('attribute'):
            attrName = aAttribute.get('name')
            attrType = aAttribute.get('attributeType')
            print ("\t\t", attrName, " = plainObject.", attrName, sep="", file=f)
        for aRelation in atype.findall('relationship'):
            relationName = aRelation.get('name')
            relationType = aRelation.get('destinationEntity')
            toMany = aRelation.get('toMany')
            isOrdered = aRelation.get('ordered') == "YES"
            if toMany:
                #if self: many  <-> child: one - safely remove
                #if self: many  <-> child: many - removeFromReversEntityName
                print("\n\t\tdeleteEntities(&", relationName, ")", sep="", file=f)
                print("\t\tif let itemsMP = plainObject.", relationName, " {\n", sep="", file=f)
                setName = "fromPlainObjectArrayOrdered" if isOrdered else "fromPlainObjectArray"
                print("\t\t\t", relationName, " = SerializationHelper<", relationType, ">.", setName, "(itemsMP, context: context, initClosure: {", sep="", file=f)
                print("\t\t\t\t(item: ", relationType, ") in\n", sep="", file=f)
                print("\t\t\t\titem.<#reverse relation#> = self", file=f)
                print("\t\t\t})", file=f)
                print("\t\t}", file=f)
            elif "OWNER" not in relationName.upper():
                #if self: one  <-> child: one - safely remove
                #if self: one  <-> child: many - removeFromReversEntityName
                print ("\n\t\t<#", relationName, "?.deleteEntity()#>", sep="", file=f)
                print ("\t\tif let item = plainObject.", relationName, " { ", sep="", file=f)
                print ("\t\t\t", relationName, " = lazyCreateUniqueEntity(by item, inContext: context)", sep="", file=f)
                print ("\t\t\t", relationName, "?.fillFromPlainObject(item)", sep="", file=f)
                print ("\t\t}", file=f)
        print ("\t}\n", file=f)

        #toPlainObject
        print ("\tpublic func toPlainObject() -> ", className, ".T {", sep="", file=f)
        print ("\t\tvar plainObject = ", plainObjectClass, "()\n", sep="", file=f)
        for aAttribute in atype.findall('attribute'):
            attrName = aAttribute.get('name')
            attrRightName = attrName
            attrType = aAttribute.get('attributeType')
            isInteger = "Integer" in attrType
            if isInteger:
                attrRightName = "Int("+attrName+")"
            print ("\t\tplainObject.", attrName, " = ", attrRightName, sep="", file=f)
        for aRelation in atype.findall('relationship'):
            relationName = aRelation.get('name')
            relationType = aRelation.get('destinationEntity')
            toMany = aRelation.get('toMany')
            isOrdered = aRelation.get('ordered') == "YES"
            if toMany:
                print("\n\t\tif let items = ", relationName, " as? Set<", relationType, "> {", sep="", file=f)
                print("\t\t\tplainObject.", relationName, " = ", "SerializationHelper<", relationType, ">.", "toPlainObjectArray(items)", sep="", file=f)
                print("\t\t}", file=f)
            elif "OWNER" not in relationName.upper():
                print ("\n\t\tplainObject.", relationName, " = ", relationName, "?.toPlainObject()", sep="", file=f)
        print ("\n\t\treturn plainObject",file=f)
        print ("\t}", file=f)
        #class close
        print ("}", file=f)

    f.close()


if __name__ == "__main__":
    main(sys.argv[1:])
