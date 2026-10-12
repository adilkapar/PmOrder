@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Orsers Status History'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_PM_ORDER_STATUS_HIST as select from jcds as j
                inner join I_MaintenanceOrder as i on i.MaintenanceOrderInternalID = j.objnr
                inner join tj30t  as t on t.estat = j.stat and t.spras = $session.system_language and t.stsma = 'ZALMPM'
{                
    key j.objnr as Objnr,
    key j.stat as Stat,
    key j.chgnr as Chgnr,
    j.usnam as Usnam,
    j.udate as Udate,
    j.utime as Utime,
    j.tcode as Tcode,
    j.cdtcode as Cdtcode,
    j.inact as Inact,
    j.chind as Chind,
    j._dataaging as Dataaging,
    i.MaintenanceOrder,
    t.txt30 as StatusText

}   where j.inact = ''