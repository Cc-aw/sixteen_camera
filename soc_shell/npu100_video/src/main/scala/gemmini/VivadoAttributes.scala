// Chisel 6 ships the FIRRTL annotation interfaces but not this legacy case
// class. CIRCT 1.75 supports firrtl.AttributeAnnotation natively. Keep the
// annotation in Scala so RTL regeneration retains the synthesis intent.
package firrtl {
  import firrtl.annotations.{Annotation, Target}

  case class AttributeAnnotation(target: Target, description: String) extends Annotation {
    def update(renames: RenameMap): Seq[AttributeAnnotation] = {
      renames.get(target) match {
        case None => Seq(this)
        case Some(targets) => targets.map(t => copy(target = t))
      }
    }
  }
}

package gemmini {
  import chisel3.experimental.{ChiselAnnotation, annotate}
  import firrtl.annotations.Target

  object VivadoAttributes {
    def apply(target: => Target, description: String): Unit = {
      annotate(new ChiselAnnotation {
        def toFirrtl: firrtl.annotations.Annotation =
          firrtl.AttributeAnnotation(target, description)
      })
    }
  }
}
