@AbapCatalog.sqlViewName: 'ZCDS_PM_OP'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Notification & parner'
@Metadata.ignorePropagatedAnnotations: true
define view ZV_PM_ORDER_PARTNER
  as select from ihpa as partner
      inner join   I_MaintenanceOrder as _Order on _Order.MaintenanceOrderInternalID = partner.objnr
{
  key _Order.MaintenanceOrder as MaintenanceOrder,
  key cast ( partner.parvw as char2 )       as PartnerFunction,
  key partner.counter                       as PartnerCounter,
      partner.parnr                         as Partner }
where
      partner.objnr    like 'OR%'
  and partner.parvw    =    'VU'  
  and partner.kzloesch is initial