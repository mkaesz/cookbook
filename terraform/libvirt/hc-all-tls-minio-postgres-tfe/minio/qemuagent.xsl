<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <xsl:template match="domain/devices/channel">
<xsl:copy>
    <xsl:attribute name="type">
      <xsl:value-of select="'unix'"/>
    </xsl:attribute>
     <source mode="bind"/>
     <target type="virtio" name="org.qemu.guest_agent.0"/>
  </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
