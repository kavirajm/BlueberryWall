var dncNumbersSelectQuery = "(SELECT `phone_no` AS `DNC` FROM `tbl_dnc` WHERE `added_on` >= NOW() - INTERVAL 6 MONTH) UNION (SELECT `alt_phone_no` AS `DNC` FROM `tbl_dnc` WHERE `added_on` >= NOW() - INTERVAL 6 MONTH) UNION (SELECT`new_alt_num` AS `DNC` FROM `tbl_dnc` WHERE `added_on` >= NOW() - INTERVAL 6 MONTH)";
                dbCon.query(dncNumbersSelectQuery, function(error, dnc){

                    console.log(dnc);

                    var dncList = [];
                    // dnc.forEach(function(item){
                    //     if(item.DNC != null && item.DNC != 'null' && item.DNC != '' && item.DNC != undefined && item.DNC != 'undefined' ){
                    //         dncList.push(item.DNC);
                    //     }
                    // });

                    for(i=0; i<dnc.length; i++){
                        dncList.push(dnc[i].DNC);
                    }


                    csvData.forEach(function(item, index, array){


                        if(item.phoneNo1!='' && item.phoneNo1!=null && item.phoneNo1!='null' && item.phoneNo1!=undefined && item.phoneNo1!='undefined'){
                            if(dncList.indexOf(item.phoneNo1)!= -1) {
                                item.phoneNo1 = '';
                            }
                        }

                        if(item.phoneNo2!='' && item.phoneNo2!=null && item.phoneNo2!='null' && item.phoneNo2!=undefined && item.phoneNo2!='undefined'){
                            if(dncList.indexOf(item.phoneNo2)!= -1) {
                                item.phoneNo2 = '';
                            }
                        }

                        if(item.phoneNo3!='' && item.phoneNo3!=null && item.phoneNo3!='null' && item.phoneNo3!=undefined && item.phoneNo3!='undefined'){
                            if(dncList.indexOf(item.phoneNo3)!= -1) {
                                item.phoneNo3 = '';
                            }
                        }
                        

                        if(item.phoneNo1!='' || item.phoneNo2!='' || item.phoneNo3!= ''){

                            var dncValidation = "SELECT company_id FROM tbl_dnc WHERE company_id = '"+item.organizationNo+"'";
                            dbCon.query(dncValidation, function(err, row){
                                if(row.length==0){
                                    var insertLead = "INSERT INTO tbl_lists_leads(list_id, status, entry_date, country_code, organization_no, company_name, street_name, district, zip_code, phone_no, alt_phone_no, new_alt_num, email_id, revenue, website, remembrance_comment, callback_date, company_registration_year, sparrat, contact_person, company_no, kallaid, kalla, avm, pott, slutdatum, adressId, projektnr, projektAdresserId, anstnr, kommentar, skulder, projektnamn, saljare ) values ('"+ids+"', 'NEW', NOW(), '0', '"+item.organizationNo+"', '"+item.companyName+"', '"+item.streetName+"', '"+item.city+"',  "+item.zipcode+", '"+item.phoneNo1+"', '"+item.phoneNo2+"', '"+item.phoneNo3+"', '"+item.email+"', '"+item.revenue+"', '"+item.web+"', '"+item.remembranceComment+"','"+item.callbackDate+"', '"+item.registrationYear+"', '"+item.sparrat+"', '"+item.contactPerson+"', '"+item.companyNo+"', '"+item.kallaid+"', '"+item.kalla+"', '"+item.avm+"', '"+item.pott+"', '"+item.slutdatum+"', '"+item.adressId+"', '"+item.projektnr+"', '"+item.projektAdresserId+"', '"+item.anstnr+"',  '"+item.kommentar+"' ,  '"+item.skulder+"' ,  '"+item.projektnamn+"',  '"+item.saljare+"' ) "; // tbl_lists_leads Insertion 
                                    dbCon.query(insertLead, function(err, result, fields) {
                                        if(!err) {
                                            listInsertCount++;
                                            if(index == (array.length-1)){
                                                var response={status:""+listInsertCount+" Leads Inserted of "+array.length+" and  "+(array.length - listInsertCount )+" 'Urgent' Leads ommited !"}
                                                callback(response);
                                            }
                                        } else {
                                            throw err;
                                        }                
                                    });
                                }
                            });
                        } else {
                            if(index == (array.length-1)){
                                var response={status:""+listInsertCount+" Leads Inserted of "+array.length+" and  "+(array.length - listInsertCount )+" 'Urgent' Leads ommited !"}
                                callback(response);
                            }
                        }
                    });
                });