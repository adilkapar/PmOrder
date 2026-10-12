@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material Stocks'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_PM_ORDER_STOCK 
  as select from nsdm_e_mchb as s inner join
                 mara as m on m.matnr = s.matnr
{
  key s.matnr as Material,
  key s.werks as Plant,
  key s.lgort as StorageLocation,
  key s.charg as BatchNumber,
      
      // Bu satırın MCHB'den geldiğini anlamak için bir belirteç ekliyoruz
      'BATCH    '    as StockLevel, 
      @Semantics.quantity.unitOfMeasure: 'BaseUnit' // 2. Referans bağlantısını yapıyoruz
      cast ( s.clabs as menge_d preserving type )  as StockQuantity,
      m.meins as BaseUnit
      
} where s.clabs > 0
union all
  select from nsdm_e_mard as d inner join 
              mara as m on m.matnr = d.matnr
{
  key d.matnr as Material,
  key d.werks as Plant,
  key d.lgort as StorageLocation,
  
  // MARD tablosunda parti numarası olmadığı için MCHB'deki CHARG alanının 
  // veri tipiyle eşleşecek şekilde boş bir karakter dizisi atıyoruz.
  key cast( '' as charg_d ) as BatchNumber, 
      
      // Bu satırın MARD'dan geldiğini anlamak için belirteç
      'MATERIAL'  as StockLevel,
      
      cast ( d.labst as menge_d preserving type ) as StockQuantity, // kalab yerine standart serbest stok alanı labst kullanıldı
      m.meins as BaseUnit
} where d.labst > 0