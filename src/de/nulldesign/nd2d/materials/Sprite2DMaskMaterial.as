/*
 * ND2D - A Flash Molehill GPU accelerated 2D engine
 *
 * Author: Lars Gerckens
 * Copyright (c) nulldesign 2011
 * Repository URL: http://github.com/nulldesign/nd2d
 * Getting started: https://github.com/nulldesign/nd2d/wiki
 *
 *
 * Licence Agreement
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package de.nulldesign.nd2d.materials {

    import com.adobe.utils.AGALMiniAssembler;

    import de.nulldesign.nd2d.geom.Face;
    import de.nulldesign.nd2d.geom.UV;
    import de.nulldesign.nd2d.geom.Vertex;
    import de.nulldesign.nd2d.utils.TextureHelper;

    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.textures.Texture;
    import flash.geom.Matrix3D;
    import flash.geom.Point;

    public class Sprite2DMaskMaterial extends Sprite2DMaterial {

        protected const DEFAULT_VERTEX_SHADER:String =
                "m44 op, va0, vc0   \n" + // vertex * clipspace
                "mov v0, va1 \n"; // copy uv

        protected const DEFAULT_FRAGMENT_SHADER:String =
                "mov ft0, v0                                    \n" + // get interpolated uv coords
                "tex ft1, ft0, fs0 <2d,clamp,linear,nomip>      \n" + // sample texture
                "mul ft1, ft1, fc0                              \n" + // mult with color
                "tex ft2, ft0, fs1 <2d,clamp,linear,nomip>      \n" + // sample mask
                "mul ft1, ft1, ft2                              \n" + // mult mask color with tex color
                "mov oc, ft1                                    \n";  // output color

        public var maskModelMatrix:Matrix3D;
        public var maskBitmap:BitmapData;

        protected var maskTexture:Texture;
        protected var maskDimensions:Point;

        protected static var maskProgramData:ProgramData;

        public function Sprite2DMaskMaterial(textureObject:Object) {
            super(textureObject);
        }

        override protected function prepareForRender(context:Context3D):Boolean {

            if(!texture) {
                texture = TextureHelper.generateTextureFromBitmap(context, spriteSheet.bitmapData, false);
            }

            if(!maskTexture) {
                maskDimensions = TextureHelper.getTextureDimensionsFromBitmap(maskBitmap);
                maskTexture = TextureHelper.generateTextureFromBitmap(context, maskBitmap, false);
            }

            context.setProgram(programData.program);
            context.setBlendFactors(blendMode.src, blendMode.dst);
            context.setTextureAt(0, texture);
            context.setTextureAt(1, maskTexture);
            context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
            context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2); // uv

            refreshClipspaceMatrix();

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, clipSpaceMatrix, true);
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0,
                                                  Vector.<Number>([ color.x, color.y, color.z, color.w ]));

            // TODO: SpriteSheets, TextureAtlas!!!

            return true;
        }

        override protected function clearAfterRender(context:Context3D):void {
            context.setTextureAt(0, null);
            context.setTextureAt(1, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(2, null);
        }

        override protected function addVertex(context:Context3D, buffer:Vector.<Number>, v:Vertex, uv:UV,
                                              face:Face):void {

            fillBuffer(buffer, v, uv, face, "PB3D_POSITION", 2);
            fillBuffer(buffer, v, uv, face, "PB3D_UV", 2);
        }

        override protected function initProgram(context:Context3D):void {
            if(!maskProgramData) {
                var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, DEFAULT_VERTEX_SHADER);

                var colorFragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                colorFragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, DEFAULT_FRAGMENT_SHADER);

                maskProgramData = new ProgramData(null, null, null, null);
                maskProgramData.numFloatsPerVertex = 4;
                maskProgramData.program = context.createProgram();
                maskProgramData.program.upload(vertexShaderAssembler.agalcode, colorFragmentShaderAssembler.agalcode);
            }

            programData = maskProgramData;
        }

        override public function cleanUp():void {

        }
    }
}