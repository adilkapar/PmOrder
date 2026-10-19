@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Orsers Status History'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_PM_ORDER_STATUS_TXT as select from  tj30t  as t 
{                
    key t.estat as Stat,
    t.txt30 as StatusText
}   where t.spras = $session.system_language and t.stsma = 'ZALMPM'
