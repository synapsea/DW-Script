{**********************************************************************}
{                                                                      }
{    "The contents of this file are subject to the Mozilla Public      }
{    License Version 1.1 (the "License"); you may not use this         }
{    file except in compliance with the License. You may obtain        }
{    a copy of the License at http://www.mozilla.org/MPL/              }
{                                                                      }
{    Software distributed under the License is distributed on an       }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express       }
{    or implied. See the License for the specific language             }
{    governing rights and limitations under the License.               }
{                                                                      }
{    Based on WriteJPEG example from OpenGL24.de                       }
{    http://www.opengl24.de/header/libjpeg                             }
{                                                                      }
{    Further changes Copyright Creative IT.                            }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsJPEGEncoder;

interface

uses
   SysUtils,
   dwsUtils,
   libJPEG,
   dwsJPEGEncoderOptions, dwsDataContext;

function CompressJPEG(rgbData : Pointer; width, height, quality : Integer;
                      const options : TJPEGOptions = [];
                      const comment : RawByteString = '') : RawByteString;

function DecompressJPEG_RGBA(jpegData : Pointer; jpegDataLength : Integer;
                             downscale : Integer; var w, h : Integer) : TData;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

type
   my_dest_mgr_ptr = ^my_dest_mgr;
   my_dest_mgr = record
      pub: jpeg_destination_mgr;

      DestStream: TWriteOnlyBlockStream;
      DestBuffer: array [1..4096] of byte;
   end;

procedure error_exit(cinfo: j_common_ptr); cdecl;
var
   msg: String;
begin
   SetLength(msg, 256);
   cinfo^.err^.format_message(cinfo, PChar(msg));

   cinfo^.global_state := 0;

   jpeg_abort(cinfo);

   raise Exception.CreateFmt('ERROR [%d] %s', [cinfo^.err^.msg_code, msg]);
end;


procedure output_message(cinfo: j_common_ptr); cdecl;
begin
   // ignore messages for now
end;


procedure init_destination(cinfo: j_compress_ptr); cdecl;
begin
end;

function empty_output_buffer(cinfo: j_compress_ptr): boolean; cdecl;
var
   dest: my_dest_mgr_ptr;
begin
   dest := my_dest_mgr_ptr(cinfo^.dest);

   if dest^.pub.free_in_buffer < Cardinal(Length(dest^.DestBuffer)) then begin
      // write complete buffer
      dest^.DestStream.Write(dest^.DestBuffer[1], SizeOf(dest^.DestBuffer));

      // reset buffer
      dest^.pub.next_output_byte := @dest^.DestBuffer[1];
      dest^.pub.free_in_buffer := Length(dest^.DestBuffer);
   end;

   Result := True;
end;


procedure term_destination(cinfo: j_compress_ptr); cdecl;
var
   i: Integer;
   dest: my_dest_mgr_ptr;
begin
   dest := my_dest_mgr_ptr(cinfo^.dest);

   for i := low(dest^.DestBuffer) to High(dest^.DestBuffer) do begin
      // check for endblock
      if (dest^.DestBuffer[i] = $FF) and (dest^.DestBuffer[i +1] = JPEG_EOI) then begin
         // write endblock
         dest^.DestStream.Write(dest^.DestBuffer[i], 2);
         // leave
         Break;
      end else dest^.DestStream.Write(dest^.DestBuffer[i], 1);
   end;
end;

// CompressJPEG
//
function CompressJPEG(rgbData : Pointer; width, height, quality : Integer;
                      const options : TJPEGOptions = [];
                      const comment : RawByteString = '') : RawByteString;
var
   wobs : TWriteOnlyBlockStream;
   jpeg: jpeg_compress_struct;
   jpeg_err: jpeg_error_mgr;
   prow : PByteArray;
   y : Integer;
begin
   if not libJPEG_initialized then
      if not init_libJPEG then
         raise Exception.CreateFmt('libJPEG not found (%s)', [ LIB_JPEG_NAME ]);

   wobs:=TWriteOnlyBlockStream.AllocFromPool;
   try
      FillChar(jpeg, SizeOf(jpeg_compress_struct), $00);
      FillChar(jpeg_err, SizeOf(jpeg_error_mgr), $00);

      // error managment
      jpeg.err := jpeg_std_error(@jpeg_err);
      jpeg_err.error_exit := error_exit;
      jpeg_err.output_message := output_message;

      // compression struct
      jpeg_create_compress(@jpeg);

      if jpeg.dest = nil then begin
         // allocation space for streaming methods
         jpeg.dest := jpeg.mem^.alloc_small(@jpeg, JPOOL_PERMANENT, SizeOf(my_dest_mgr));

         // seeting up custom functions
         with my_dest_mgr_ptr(jpeg.dest)^ do begin
            pub.init_destination    := init_destination;
            pub.empty_output_buffer := empty_output_buffer;
            pub.term_destination    := term_destination;

            pub.next_output_byte  := @DestBuffer[1];
            pub.free_in_buffer    := Length(DestBuffer);

            DestStream := wobs;
         end;
      end;

      // very important state
      jpeg.global_state := CSTATE_START;

      jpeg.image_width := width;
      jpeg.image_height := height;
      jpeg.input_components := 3;
      jpeg.in_color_space := JCS_RGB;

      // setting defaults
      jpeg_set_defaults(@jpeg);

      if jpgoOptimize in options then
         jpeg.optimize_coding := 1;
      if jpgoNoJFIFHeader in options then
         jpeg.write_JFIF_header := 0; //!!!!!!!!!!!!
      if jpgoProgressive in options then
         jpeg_simple_progression(@jpeg);

      // compression quality
      jpeg_set_quality(@jpeg, quality, True);

      // start compression
      jpeg_start_compress(@jpeg, true);

      // write marker (comment)
      if comment<>'' then
         jpeg_write_marker(@jpeg, JPEG_COM, Pointer(comment), Length(comment)+1);

      prow := PByteArray(rgbData);
      for y:=0 to height-1 do begin
         jpeg_write_scanlines(@jpeg, @prow, 1);
         prow := @prow[width*3];
      end;

      // finish compression
      jpeg_finish_compress(@jpeg);

      // *** finallization ***
      // destroy compression
      jpeg_destroy_compress(@jpeg);


      Result:=wobs.ToRawBytes;

   finally
      wobs.ReturnToPool;
   end;
end;

// DecompressJPEG_RGBA
//
function DecompressJPEG_RGBA(jpegData : Pointer; jpegDataLength : Integer;
                             downscale : Integer; var w, h : Integer) : TData;
var
   JpegErr: jpeg_error_mgr;
   Jpeg: jpeg_decompress_struct;
   x, y : Integer;
   p : PVarData;
   buf : array of Cardinal;
begin
   if not libJPEG_initialized then
      if not init_libJPEG then
         raise Exception.CreateFmt('libJPEG not found (%s)', [ LIB_JPEG_NAME ]);

   FillChar(Jpeg, SizeOf(Jpeg), 0);
   FillChar(JpegErr, SizeOf(JpegErr), 0);

   jpeg_create_decompress(@Jpeg);
   try
      jpeg.err := jpeg_std_error(@JpegErr);
      JpegErr.error_exit := error_exit;
      JpegErr.output_message := output_message;
      jpeg_mem_src(@Jpeg, jpegData, jpegDataLength);
      jpeg_read_header(@jpeg, False);

      jpeg.out_color_space := JCS_EXT_RGBA;

      jpeg.scale_num := 1;
      if downscale <= 0 then
         jpeg.scale_denom := 1
      else jpeg.scale_denom := downscale;

      if downscale <= 0 then begin
         jpeg.do_block_smoothing := 1;
         jpeg.do_fancy_upsampling := 1;
         jpeg.dct_method := JDCT_ISLOW;
      end else begin
         jpeg.do_block_smoothing := 0;
         jpeg.do_fancy_upsampling := 0;
         jpeg.dct_method := JDCT_IFAST;
      end;

      jpeg_start_decompress(@Jpeg);
      try
         w := jpeg.output_width;
         h := jpeg.output_height;

         SetLength(buf, w);
         SetLength(Result, w*h);
         p := @Result[0];

         for y:=0 to h-1 do begin
            var pbuf := @buf[0];
            jpeg_read_scanlines(@jpeg, @pbuf, 1);
            for x := 0 to w-1 do begin
               p.VType := varInt64;
               p.VInt64 := buf[x];
               Inc(p);
            end;
         end;
      finally
         jpeg_finish_decompress(@Jpeg);
      end;
   finally
      jpeg_destroy_decompress(@Jpeg);
   end;
end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

finalization

  quit_libJPEG;

end.
