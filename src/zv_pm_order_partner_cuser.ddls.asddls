@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Partner Current User'
@Metadata.ignorePropagatedAnnotations: true
define view Entity ZV_PM_ORDER_PARTNER_CUSER
  as select from ihpa as partner
      inner join   I_MaintenanceOrder as _Order on _Order.MaintenanceOrderInternalID = partner.objnr
{
  key _Order.MaintenanceOrder as MaintenanceOrder,
      max( case when partner.parnr = $session.user then 'X' else '' end   ) as currentuser } 
where
      partner.objnr    like 'OR%'
  and partner.parvw    =    'VU'
  and partner.kzloesch is initial
  group by _Order.MaintenanceOrder